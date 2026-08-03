function result = run_psma_tcp(env, config, seeds)

stream = RandStream('mt19937ar', 'Seed', seeds.policy);
feedbackStream = RandStream('mt19937ar', 'Seed', seeds.feedback);
K = config.K;
L = config.numLinksPerPath;
W = config.numEntities;
M = config.numTaskTypes;
d = config.d;
N = config.psma.gibbsSweeps;
epsilon = env.integrationNoise;

alg = cell(1, L);
arm = cell(1, W);
for position = 1:L
    alg{position} = PSMATCPAlg(position, d, numel(config.S{position}), M, env.public.taskWeights);
end
for entity = 1:W
    arm{entity} = PSMATCPArm(entity, d, env.public.taskWeights);
end

result = initialize_result('PS-MA (link-level)', config.T, seeds, epsilon);
R_t = zeros(d, W);
X_t = zeros(d, L);
previousPath = 0;

for t = 1:config.T
    tic;
    if t == 1
        for entity = 1:W
            R_t(:, entity) = arm{entity}.sample(stream);
        end
        for position = 1:L
            X_t(:, position) = alg{position}.sample(stream);
        end
    else
                        for sweep = 1:N
            for entity = 1:W
                R_t(:, entity) = arm{entity}.sample(stream);
            end
            for position = 1:L
                selectedEntity = env.public.P{previousPath}(position);
                localArm = find(env.public.S{position} == selectedEntity);
                alg{position} = alg{position}.update(0, localArm, ...
                    env.public.task.type(t), numel(env.public.S{position}), M, R_t(:, env.public.S{position}));
            end
            for position = 1:L
                X_t(:, position) = alg{position}.sample(stream);
            end
            for entity = 1:W
                arm{entity} = arm{entity}.update(0, env.public.task.type(t), ...
                    X_t(:, env.public.index(entity)));
            end
        end
    end

        predictedCost = zeros(1, K);
    taskType = env.public.task.type(t);
    for path = 1:K
        for position = 1:L
            entity = env.public.P{path}(position);
            predictedCost(path) = predictedCost(path) + env.public.Weight(position) * ...
                mean(sigmoid_stable(X_t(:, position)' * ...
                (R_t(:, entity) - env.public.taskWeights(:, taskType)) + epsilon));
        end
    end
    [~, chosenPath] = min(predictedCost);
    result.diagnostics.predictedPathCost{t} = predictedCost;
    result.diagnostics.linkGlobalDraw{t} = X_t;
    result.diagnostics.entityDraw{t} = R_t;
    result.decisionSeconds(t) = toc;

    observation = observe_selected_arm_tcp(env, config, feedbackStream, t, chosenPath, previousPath);

    tic;
            for position = 1:L
        entity = env.public.P{chosenPath}(position);
        localArm = find(env.public.S{position} == entity);
        feedback = observation.linkLogitFeedback(position);
        alg{position} = alg{position}.update(feedback, localArm, taskType, ...
            numel(env.public.S{position}), M, R_t(:, env.public.S{position}));
        arm{entity} = arm{entity}.update(feedback, taskType, X_t(:, env.public.index(entity)));
    end
    result.diagnostics.linkPosteriorInput{t} = observation.linkLogitFeedback;
    result.updateSeconds(t) = toc;

    result = append_observation(result, t, chosenPath, env.public.candidateIds{t}, observation);
    previousPath = chosenPath;
end

result.diagnostics.gibbsSweeps = N;
instantRegret = env.oracle.expectedProcessingCost(sub2ind([config.K, config.T], ...
    result.selectedArm, 1:config.T)) - min(env.oracle.expectedProcessingCost, [], 1);
recordAt = config.recordEvery:config.recordEvery:config.T;
result.finalRegret = sum(instantRegret);
result.finalDelay = sum(result.processingCost);
cumulativeRegret = cumsum(instantRegret);
cumulativeDelay = cumsum(result.processingCost);
result.Regret = [0, cumulativeRegret(recordAt)];
result.Delay = [0, cumulativeDelay(recordAt)];
result.runtimeSeconds = sum(result.decisionSeconds) + sum(result.updateSeconds);
end

function result = initialize_result(name, T, seeds, scoringNoise)
result.method = name;
result.selectedArm = zeros(1, T);
result.candidateIds = cell(1, T);
result.reward = zeros(1, T);
result.processingCost = zeros(1, T);
result.switchCost = zeros(1, T);
result.totalCost = zeros(1, T);
result.decisionSeconds = zeros(1, T);
result.updateSeconds = zeros(1, T);
result.seed = seeds.policy;
result.policySeed = seeds.policy;
result.feedbackSeed = seeds.feedback;
result.diagnostics.predictedPathCost = cell(1, T);
result.diagnostics.linkGlobalDraw = cell(1, T);
result.diagnostics.entityDraw = cell(1, T);
result.diagnostics.linkPosteriorInput = cell(1, T);
result.diagnostics.scoringNoise = scoringNoise;
end

function result = append_observation(result, t, path, candidates, observation)
result.selectedArm(t) = path;
result.candidateIds{t} = candidates;
result.reward(t) = observation.reward;
result.processingCost(t) = observation.processingCost;
result.switchCost(t) = observation.switchCost;
result.totalCost(t) = observation.totalCost;
end