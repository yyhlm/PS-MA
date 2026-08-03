function result = run_hlinucb_allm(env, config, policySeed, feedbackSeed)

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

Arm_cp = repmat(hLinUCBArm(1, d, Theta), 1, K);
for i = 1:K
    Arm_cp(i) = hLinUCBArm(i, d, Theta);
end
Arm_cm = repmat(hLinUCBArm(1, d, Vartheta), 1, K);
for i = 1:K
    Arm_cm(i) = hLinUCBArm(i, d, Vartheta);
end
A_cp = eye(d);
A_inv_cp = eye(d);
b_cp = zeros(d, 1);
A_cm = eye(d);
A_inv_cm = eye(d);
b_cm = zeros(d, 1);
x_t = unifrnd(0, 1, d, 1);
y_t = unifrnd(0, 1, d, 1);

delta = 0.01;
alpha1_cp = sqrt(log(2 * T * K / delta) / 2) + 1;
alpha2_cp = sqrt(log(2 * T * K / delta) / 2) + 1;
alpha1_cm = sqrt(log(2 * T * K / delta) / 2) + 1;
alpha2_cm = sqrt(log(2 * T * K / delta) / 2) + 1;

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
    np = num_pool(t);
    pool = candidate_pool(t, 1:np);
    Value = zeros(1, np);
    for i = 1:np
        k = pool(i);
        Value(i) = Arm_cp(k).calculate(alpha1_cp, alpha2_cp, x_t, A_inv_cp, m) + ...
                   Arm_cm(k).calculate(alpha1_cm, alpha2_cm, y_t, A_inv_cm, m);
    end
    s = [];
    if t ~= 1
        s = find(pool == arm);
        if ~isempty(s)
            Value(s) = Value(s) - SwitchCost;
        end
    end
    [~, index] = min(Value);
    arm = pool(index);
    selectedArm(t) = arm;

    observation = observe_allm_arm(env, config, t, arm, selectedArm(t - (t > 1)), feedbackStream);
    reward_cp = observation.rewardCompute;
    processingCost(t) = observation.processingCost;
    switchCost(t) = observation.switchCost;
    totalCost(t) = observation.totalCost;
    A_cp = A_cp + (Arm_cp(arm).r_t - Theta(:, m)) * (Arm_cp(arm).r_t - Theta(:, m))';
    b_cp = b_cp + (Arm_cp(arm).r_t - Theta(:, m)) * observation.logitCompute;
    x_t = A_cp \ b_cp;
    A_inv_cp = inv(A_cp);
    Arm_cp(arm) = Arm_cp(arm).update(observation.logitCompute, m, x_t);

    reward_cm = observation.rewardComm;
    A_cm = A_cm + (Arm_cm(arm).r_t - Vartheta(:, m)) * (Arm_cm(arm).r_t - Vartheta(:, m))';
    b_cm = b_cm + (Arm_cm(arm).r_t - Vartheta(:, m)) * observation.logitComm;
    y_t = A_cm \ b_cm;
    A_inv_cm = inv(A_cm);
    Arm_cm(arm) = Arm_cm(arm).update(observation.logitComm, m, y_t);

    regret = regret + env.oracle.u(arm, m) - env.oracle.minn(t);
    delay = delay + observation.totalCost;
    if mod(t, recordEvery) == 0
        Regret = [Regret, regret];
        Delay = [Delay, delay];
    end
end

result.method = 'hLinUCB';
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