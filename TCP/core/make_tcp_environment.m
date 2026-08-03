function env = make_tcp_environment(config, seed)

stream = RandStream('mt19937ar', 'Seed', seed);
K = config.K;
T = config.T;
d = config.d;
L = config.numLinksPerPath;
W = config.numEntities;
M = config.numTaskTypes;

truth.X = rand(stream, d, L);
truth.R = rand(stream, d, W);
truth.Theta = rand(stream, d, M);
task.type = randi(stream, M, 1, T);

candidateIds = cell(1, T);
for t = 1:T
    candidateIds{t} = (1:K).';
end

baseLogitByTask = zeros(W, M);
for entity = 1:W
    position = config.index(entity);
    for taskType = 1:M
        baseLogitByTask(entity, taskType) = truth.X(:, position)' * ...
            (truth.R(:, entity) - truth.Theta(:, taskType));
    end
end

integrationNoise = config.feedbackNoiseStd * randn(stream, 1, config.simulates);
expectedProcessingCost = zeros(K, T);
baseLogitByPath = zeros(K, L, T);
for t = 1:T
    taskType = task.type(t);
    for path = 1:K
        entityIds = config.P{path};
        linkLogits = baseLogitByTask(entityIds, taskType);
        baseLogitByPath(path, :, t) = linkLogits;
        expectedLinks = zeros(1, L);
        for position = 1:L
            expectedLinks(position) = mean(sigmoid_stable( ...
                linkLogits(position) + integrationNoise));
        end
        expectedProcessingCost(path, t) = sum(config.Weight .* expectedLinks(:).');
    end
end

env.public.task = task;
env.public.taskWeights = truth.Theta;
env.public.knownContext = truth.Theta(:, task.type);
env.public.candidateIds = candidateIds;
env.public.K = K;
env.public.T = T;
env.public.d = d;
env.public.M = M;
env.public.Weight = config.Weight;
env.public.P = config.P;
env.public.index = config.index;
env.public.S = config.S;
env.public.totalPathWeight = config.totalPathWeight;
env.public.switchCost = 0;
env.oracle.baseLogitByTask = baseLogitByTask;
env.oracle.baseLogitByPath = baseLogitByPath;
env.oracle.expectedProcessingCost = expectedProcessingCost;
env.oracle.expectedReward = config.totalPathWeight - expectedProcessingCost;
env.truth = truth;
env.integrationNoise = integrationNoise;
env.metadata.seed = seed;
end