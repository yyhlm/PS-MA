function result = run_psma_allm(env, config, policySeed, feedbackSeed)

rng(policySeed);
feedbackStream = RandStream('mt19937ar', 'Seed', feedbackSeed);
K = config.K;
T = config.T;
d = config.d;
M = config.M;
N = config.psma.gibbsSweeps;
alpha = config.alpha;
beta = config.beta;

Theta = env.public.taskComputeWeights;
Vartheta = env.public.taskCommWeights;
candidate_pool = env.public.candidatePool;
num_pool = env.public.numPool;
Tasktype = env.public.taskType;
SwitchCost = config.switchCost;

epsilon = env.integrationNoise;

Alg_cp = PSMCMCAlg(d, K, M, Theta);
Arm_cp = repmat(PSMCMCArm(1, d, Theta), 1, K);
for i = 1:K
    Arm_cp(i) = PSMCMCArm(i, d, Theta);
end
Alg_cm = PSMCMCAlg(d, K, M, Vartheta);
Arm_cm = repmat(PSMCMCArm(1, d, Vartheta), 1, K);
for i = 1:K
    Arm_cm(i) = PSMCMCArm(i, d, Vartheta);
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
    if t == 1
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
    else
        for sweep = 1:N
            R_t = zeros(d, K);
            for j = 1:K
                R_t(:, j) = Arm_cp(j).sample();
            end
            Alg_cp = Alg_cp.update(0, arm, m, K, M, R_t);
            x_t = Alg_cp.sample();
            for j = 1:K
                Arm_cp(j) = Arm_cp(j).update(0, m, x_t);
            end
        end
        for sweep = 1:N
            Q_t = zeros(d, K);
            for j = 1:K
                Q_t(:, j) = Arm_cm(j).sample();
            end
            Alg_cm = Alg_cm.update(0, arm, m, K, M, Q_t);
            y_t = Alg_cm.sample();
            for j = 1:K
                Arm_cm(j) = Arm_cm(j).update(0, m, y_t);
            end
        end
    end

    np = num_pool(t);
    pool = candidate_pool(t, 1:np);
    u_t = zeros(1, np);
    for i = 1:np
        k = pool(i);
        u_t(i) = alpha * mean(logsig(x_t' * (R_t(:, k) - Theta(:, m)) + epsilon)) + ...
                 beta * mean(logsig(y_t' * (Q_t(:, k) - Vartheta(:, m)) + epsilon));
    end
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
    reward_cm = observation.rewardComm;
    processingCost(t) = observation.processingCost;
    switchCost(t) = observation.switchCost;
    totalCost(t) = observation.totalCost;
    Alg_cp = Alg_cp.update(observation.logitCompute, arm, m, K, M, R_t);
    Arm_cp(arm) = Arm_cp(arm).update(observation.logitCompute, m, x_t);
    Alg_cm = Alg_cm.update(observation.logitComm, arm, m, K, M, Q_t);
    Arm_cm(arm) = Arm_cm(arm).update(observation.logitComm, m, y_t);

    regret = regret + env.oracle.u(arm, m) - env.oracle.minn(t);
    delay = delay + observation.totalCost;
    if mod(t, recordEvery) == 0
        Regret = [Regret, regret];
        Delay = [Delay, delay];
    end
end

result.method = 'PS-MA';
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