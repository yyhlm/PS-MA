function result = run_glmucb_tcp(env, config, seeds)

stream = RandStream('mt19937ar', 'Seed', seeds.policy);
feedbackStream = RandStream('mt19937ar', 'Seed', seeds.feedback);
K = config.K; T = config.T; d = config.d; delta = config.glmucb.delta;
identityFeature = eye(K); featureDim = d + K;
A = eye(featureDim); Ainv = eye(featureDim); b = zeros(featureDim, 1); theta = rand(stream, featureDim, 1);
alpha = sqrt(log(2 * T * K / delta) / 2);
epsilon = randn(stream, 1, config.simulates);
regret = 0; delay = 0; Regret = 0; Delay = 0; previousPath = 0;
selectedArm = zeros(1, T); processingCost = zeros(1, T); switchCost = zeros(1, T);
totalCost = zeros(1, T); reward = zeros(1, T); decisionSeconds = zeros(1, T); updateSeconds = zeros(1, T);
tickStart = tic;

for t = 1:T
    decisionTick = tic;
    taskFeature = env.public.taskWeights(:, env.public.task.type(t));
    scores = zeros(1, K);
    for path = 1:K
        x = [taskFeature; identityFeature(:, path)];
        scores(path) = mean(logsig(theta' * x + epsilon)) + (alpha + 1) * sqrt(x' * Ainv * x);
    end
    [~, path] = max(scores); selectedArm(t) = path;
    decisionSeconds(t) = toc(decisionTick);

    updateTick = tic;
    observation = observe_selected_arm_tcp(env, config, feedbackStream, t, path, previousPath);
    processingCost(t) = observation.processingCost; totalCost(t) = observation.totalCost;
    reward(t) = config.totalPathWeight - processingCost(t);
    normalizedReward = 1 - processingCost(t) / config.totalPathWeight;
    x = [taskFeature; identityFeature(:, path)];
    A = A + x * x'; b = b + logit_clipped(normalizedReward, config.feedbackEpsilon) * x;
    theta = A \ b; Ainv = inv(A);
    updateSeconds(t) = toc(updateTick);

    delay = delay + processingCost(t);
    regret = regret + env.oracle.expectedProcessingCost(path, t) - min(env.oracle.expectedProcessingCost(:, t));
    if mod(t, config.recordEvery) == 0
        Regret = [Regret, regret];
        Delay = [Delay, delay];
    end
    previousPath = path;
end

result.method = 'GLM-UCB'; result.selectedArm = selectedArm;
result.Regret = Regret; result.Delay = Delay; result.finalRegret = regret; result.finalDelay = delay;
result.processingCost = processingCost; result.switchCost = switchCost; result.totalCost = totalCost;
result.reward = reward; result.decisionSeconds = decisionSeconds; result.updateSeconds = updateSeconds;
result.runtimeSeconds = toc(tickStart); result.seed = seeds.policy; result.policySeed = seeds.policy; result.feedbackSeed = seeds.feedback;
result.diagnostics.featureSource = 'public_task_descriptor_plus_one_hot_path_id';
result.diagnostics.feedbackMapping = 'scalar_complement_normalized_path_cost';
result.diagnostics.actionSelection = 'source_argmax'; result.diagnostics.featureDimension = featureDim;
result.diagnostics.delta = delta;
end