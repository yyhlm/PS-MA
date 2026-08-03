function result = run_glmucb_allm(env, config, policySeed, feedbackSeed)

rng(policySeed);
feedbackStream = RandStream('mt19937ar', 'Seed', feedbackSeed);
K = config.K; T = config.T; d = config.d; delta = config.glmucb.delta;
identityFeature = eye(K); featureDim = 2 * d + K;
A = eye(featureDim); Ainv = eye(featureDim); b = zeros(featureDim, 1); theta = rand(featureDim, 1);
alpha = sqrt(log(2 * T * K / delta) / 2);
epsilon = randn(1, config.simulates);
regret = 0; delay = 0; Regret = 0; Delay = 0;
selectedArm = zeros(1, T); processingCost = zeros(1, T);
switchCost = zeros(1, T); totalCost = zeros(1, T); reward = zeros(1, T);
decisionSeconds = zeros(1, T); updateSeconds = zeros(1, T);
tickStart = tic;

for t = 1:T
    decisionTick = tic;
    taskType = env.public.taskType(t);
    taskFeature = [env.public.taskComputeWeights(:, taskType); env.public.taskCommWeights(:, taskType)];
    pool = env.public.candidatePool(t, 1:env.public.numPool(t));
    scores = zeros(1, numel(pool));
    for i = 1:numel(pool)
        x = [taskFeature; identityFeature(:, pool(i))];
        scores(i) = mean(logsig(theta' * x + epsilon)) + (alpha + 1) * sqrt(x' * Ainv * x);
    end
    previousArm = 0; if t > 1, previousArm = selectedArm(t - 1); end
    retainedIndex = find(pool == previousArm);
    if ~isempty(retainedIndex)
        scores(retainedIndex) = scores(retainedIndex) - config.switchCost;
    end
    [~, index] = max(scores);
    arm = pool(index); selectedArm(t) = arm;
    decisionSeconds(t) = toc(decisionTick);

    updateTick = tic;
    observation = observe_allm_arm(env, config, t, arm, previousArm, feedbackStream);
    processingCost(t) = observation.processingCost;
    switchCost(t) = observation.switchCost;
    totalCost(t) = observation.totalCost;
    normalizedReward = 1 - observation.processingCost / (config.alpha + config.beta);
    reward(t) = normalizedReward;
    x = [taskFeature; identityFeature(:, arm)];
    A = A + x * x'; b = b + bounded_logit(normalizedReward) * x;
    theta = A \ b; Ainv = inv(A);
    updateSeconds(t) = toc(updateTick);

    regret = regret + env.oracle.u(arm, env.public.taskType(t)) - env.oracle.minn(t);
    delay = delay + totalCost(t);
    if mod(t, config.recordEvery) == 0
        Regret = [Regret, regret];
        Delay = [Delay, delay];
    end
end

result.method = 'GLM-UCB'; result.selectedArm = selectedArm;
result.Regret = Regret; result.Delay = Delay; result.finalRegret = regret; result.finalDelay = delay;
result.processingCost = processingCost; result.switchCost = switchCost; result.totalCost = totalCost;
result.reward = reward; result.decisionSeconds = decisionSeconds; result.updateSeconds = updateSeconds;
result.runtimeSeconds = toc(tickStart); result.seed = policySeed; result.feedbackSeed = feedbackSeed;
result.diagnostics.featureSource = 'public_task_descriptor_plus_one_hot_server_id';
result.diagnostics.feedbackMapping = 'scalar_complement_normalized_total_cost';
result.diagnostics.actionSelection = 'source_argmax_with_stay_bonus'; result.diagnostics.featureDimension = featureDim;
result.diagnostics.delta = delta;
end

function value = bounded_logit(probability)
probability = min(max(probability, 1e-12), 1 - 1e-12);
value = log(probability) - log1p(-probability);
end