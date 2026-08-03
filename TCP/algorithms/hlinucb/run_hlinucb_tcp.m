function result = run_hlinucb_tcp(env, config, seeds)

rng(seeds.policy);
feedbackStream = RandStream('mt19937ar', 'Seed', seeds.feedback);
K = config.K; L = config.numLinksPerPath; W = config.numEntities;
T = config.T; d = config.d; Theta = env.public.taskWeights;
Arm = repmat(TCPHLinUCBArm(1, d, Theta), 1, W);
for entity = 1:W, Arm(entity) = TCPHLinUCBArm(entity, d, Theta); end
Alg = repmat(TCPHLinUCBAlg(1, d, Theta), 1, L);
for position = 1:L, Alg(position) = TCPHLinUCBAlg(position, d, Theta); end
delta = 0.01; alpha1 = sqrt(log(2 * T * K / delta) / 2) + 1;
alpha2 = alpha1; regret = 0; delay = 0; Regret = 0; Delay = 0;
selectedArm = zeros(1, T); processingCost = zeros(1, T); reward = zeros(1, T);
recordEvery = config.recordEvery; tickStart = tic;
for t = 1:T
    taskType = env.public.task.type(t); values = zeros(1, K);
    for path = 1:K
        for position = 1:L
            entity = env.public.P{path}(position);
            feature = Arm(entity).r_t - Theta(:, taskType);
            values(path) = values(path) + Alg(position).x_t' * feature + ...
                alpha1 * sqrt(feature' * Alg(position).A_inv * feature) + ...
                alpha2 * sqrt(Alg(position).x_t' * Arm(entity).C_inv * Alg(position).x_t);
        end
    end
    [~, path] = min(values); selectedArm(t) = path;
    observation = observe_selected_arm_tcp(env, config, feedbackStream, t, path, 0);
    for position = 1:L
        entity = env.public.P{path}(position); feedback = observation.linkLogitFeedback(position);
        Alg(position) = Alg(position).update(feedback, taskType, Arm(entity).r_t);
        Arm(entity) = Arm(entity).update(feedback, taskType, Alg(env.public.index(entity)).x_t);
    end
    delay = delay + observation.processingCost;
    processingCost(t) = observation.processingCost;
    reward(t) = observation.reward;
    regret = regret + env.oracle.expectedProcessingCost(path, t) - ...
        min(env.oracle.expectedProcessingCost(:, t));
    if mod(t, recordEvery) == 0, Regret = [Regret, regret]; Delay = [Delay, delay]; end
end
result = make_result('hLinUCB', selectedArm, Regret, Delay, regret, delay, toc(tickStart), seeds, processingCost, reward);
end

function result = make_result(name, selectedArm, regret, delay, finalRegret, finalDelay, runtime, seeds, processingCost, reward)
T = numel(selectedArm);
result.method = name; result.selectedArm = selectedArm; result.Regret = regret; result.Delay = delay;
result.finalRegret = finalRegret; result.finalDelay = finalDelay; result.runtimeSeconds = runtime; result.seed = seeds.policy;
result.policySeed = seeds.policy; result.feedbackSeed = seeds.feedback;
result.processingCost = processingCost; result.reward = reward; result.switchCost = zeros(1, T);
result.totalCost = processingCost; result.decisionSeconds = zeros(1, T); result.updateSeconds = zeros(1, T);
end