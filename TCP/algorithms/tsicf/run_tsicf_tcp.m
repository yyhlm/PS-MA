function result = run_tsicf_tcp(env, config, seeds)

rng(seeds.policy);
feedbackStream = RandStream('mt19937ar', 'Seed', seeds.feedback);
K = config.K; L = config.numLinksPerPath; W = config.numEntities;
T = config.T; d = config.d; Theta = env.public.taskWeights;
Arm = repmat(TCPTSICFArm(1, d, Theta), 1, W);
for entity = 1:W, Arm(entity) = TCPTSICFArm(entity, d, Theta); end
Alg = repmat(TCPTSICFAlg(1, d, Theta), 1, L);
for position = 1:L, Alg(position) = TCPTSICFAlg(position, d, Theta); end
regret = 0; delay = 0; Regret = 0; Delay = 0; selectedArm = zeros(1, T);
recordEvery = config.recordEvery; tickStart = tic;
processingCost = zeros(1, T); reward = zeros(1, T);
for t = 1:T
    taskType = env.public.task.type(t); R = zeros(d, W); X = zeros(d, L);
    for entity = 1:W, R(:, entity) = Arm(entity).sample(); end
    for position = 1:L, X(:, position) = Alg(position).sample(); end
    scores = zeros(1, K);
    for path = 1:K
        for position = 1:L
            entity = env.public.P{path}(position);
            scores(path) = scores(path) + X(:, position)' * (R(:, entity) - Theta(:, taskType));
        end
    end
    [~, path] = min(scores); selectedArm(t) = path;
    observation = observe_selected_arm_tcp(env, config, feedbackStream, t, path, 0);
    for position = 1:L
        entity = env.public.P{path}(position); feedback = observation.linkLogitFeedback(position);
        Alg(position) = Alg(position).update(feedback, taskType, R(:, entity));
        Arm(entity) = Arm(entity).update(feedback, taskType, X(:, env.public.index(entity)));
    end
    delay = delay + observation.processingCost;
    processingCost(t) = observation.processingCost;
    reward(t) = observation.reward;
    regret = regret + env.oracle.expectedProcessingCost(path, t) - ...
        min(env.oracle.expectedProcessingCost(:, t));
    if mod(t, recordEvery) == 0, Regret = [Regret, regret]; Delay = [Delay, delay]; end
end
result.method = 'TS-ICF'; result.selectedArm = selectedArm; result.Regret = Regret; result.Delay = Delay;
result.finalRegret = regret; result.finalDelay = delay; result.runtimeSeconds = toc(tickStart); result.seed = seeds.policy;
result.policySeed = seeds.policy; result.feedbackSeed = seeds.feedback;
result.processingCost = processingCost; result.reward = reward; result.switchCost = zeros(1, T);
result.totalCost = processingCost; result.decisionSeconds = zeros(1, T); result.updateSeconds = zeros(1, T);
end