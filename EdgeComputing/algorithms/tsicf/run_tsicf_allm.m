function result = run_tsicf_allm(env, config, policySeed, feedbackSeed)

rng(policySeed);
feedbackStream = RandStream('mt19937ar', 'Seed', feedbackSeed);
K = config.K;
T = config.T;
d = config.d;
M = config.M;
alpha = config.alpha;
beta = config.beta;

Theta = env.public.taskComputeWeights;
Vartheta = env.public.taskCommWeights;
candidate_pool = env.public.candidatePool;
num_pool = env.public.numPool;
Tasktype = env.public.taskType;
SwitchCost = config.switchCost;

Alg_cp = TSICFAlg(d, Theta);
Arm_cp = repmat(TSICFArm(1, d, Theta), 1, K);
for i = 1:K
    Arm_cp(i) = TSICFArm(i, d, Theta);
end
Alg_cm = TSICFAlg(d, Vartheta);
Arm_cm = repmat(TSICFArm(1, d, Vartheta), 1, K);
for i = 1:K
    Arm_cm(i) = TSICFArm(i, d, Vartheta);
end

regret = 0;
Regret = 0;
delay = 0;
Delay = 0;
arm = 0;
selectedArm = zeros(1, T);
processingCost = zeros(1, T); switchCost = zeros(1, T); totalCost = zeros(1, T);
recordEvery = config.recordEvery;
tickStart = tic;

for t = 1:T
    m = Tasktype(t);
    R_t = zeros(d, K);
    for i = 1:K
        R_t(:, i) = Arm_cp(i).sample();
    end
    x_t = Alg_cp.sample();
    Q_t = zeros(d, K);
    for i = 1:K
        Q_t(:, i) = Arm_cm(i).sample();
    end
    y_t = Alg_cm.sample();

    np = num_pool(t);
    pool = candidate_pool(t, 1:np);
    u_t = zeros(1, np);
    for i = 1:np
                        u_t(i) = x_t' * (R_t(:, i) - Theta(:, m)) ...
            + y_t' * (Q_t(:, i) - Vartheta(:, m));
    end
    s = [];
    if t ~= 1
        s = find(pool == arm);
        if ~isempty(s)
            u_t(s) = u_t(s) - SwitchCost;
        end
    end
    [~, index] = min(u_t);
    arm = pool(index);
    selectedArm(t) = arm;

    observation = observe_allm_arm(env, config, t, arm, selectedArm(t - (t > 1)), feedbackStream);
    reward_cp = observation.rewardCompute;
    processingCost(t) = observation.processingCost;
    switchCost(t) = observation.switchCost;
    totalCost(t) = observation.totalCost;
    Alg_cp = Alg_cp.update(observation.logitCompute, m, R_t(:, arm));
    Arm_cp(arm) = Arm_cp(arm).update(observation.logitCompute, m, x_t);
    reward_cm = observation.rewardComm;
    Alg_cm = Alg_cm.update(observation.logitComm, m, Q_t(:, arm));
    Arm_cm(arm) = Arm_cm(arm).update(observation.logitComm, m, y_t);

    regret = regret + env.oracle.u(arm, m) - env.oracle.minn(t);
    delay = delay + observation.totalCost;
    if mod(t, recordEvery) == 0
        Regret = [Regret, regret];
        Delay = [Delay, delay];
    end
end

result.method = 'TS-ICF';
result.selectedArm = selectedArm;
result.Regret = Regret;
result.Delay = Delay;
result.finalRegret = regret;
result.finalDelay = delay;
result.processingCost = processingCost;
result.switchCost = switchCost;
result.totalCost = totalCost;
result.runtimeSeconds = toc(tickStart);
result.seed = policySeed;
result.feedbackSeed = feedbackSeed;
end