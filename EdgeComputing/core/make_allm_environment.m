function env = make_allm_environment(config, seed)

rng(seed);

K = config.K;
T = config.T;
d = config.d;
M = config.M;
alpha = config.alpha;
beta = config.beta;

x = unifrnd(0, 1, d, 1);
y = unifrnd(0, 1, d, 1);
R = zeros(d, K);
Q = zeros(d, K);
for i = 1:K
    R(:, i) = unifrnd(0, 1, d, 1);
    Q(:, i) = unifrnd(0, 1, d, 1);
end
Theta = zeros(d, M);
Vartheta = zeros(d, M);
for i = 1:M
    Theta(:, i) = unifrnd(0, 1, d, 1);
    Vartheta(:, i) = unifrnd(0, 1, d, 1);
end

u_inpro_cp = zeros(K, M);
u_inpro_cm = zeros(K, M);
for i = 1:K
    for j = 1:M
        u_inpro_cp(i, j) = x' * (R(:, i) - Theta(:, j));
        u_inpro_cm(i, j) = y' * (Q(:, i) - Vartheta(:, j));
    end
end
simulates = config.simulates;
epsilon = normrnd(0, 1, 1, simulates);
u_cp = zeros(K, M);
u_cm = zeros(K, M);
for i = 1:K
    for j = 1:M
        u_cp(i, j) = alpha * mean(logsig(u_inpro_cp(i, j) + epsilon));
        u_cm(i, j) = beta * mean(logsig(u_inpro_cm(i, j) + epsilon));
    end
end
u = u_cp + u_cm;

Tasktype = unidrnd(M, 1, T);

SwitchCost = config.switchCost;
lambda = config.lambda;
loc = unifrnd(1, K);
trace = lambda * unifrnd(-1, 1, 1, T);
poolSize = round(0.2 * K);
candidate_pool = zeros(T, poolSize);
candidate_pool(1, :) = floor(loc) - 0.1 * K + sort(randperm(poolSize));
for i = 2:T
    loc = loc + trace(i);
    if loc > K
        loc = K;
        candidate_pool(i, :) = floor(loc) - 0.1 * K + sort(randperm(poolSize)) - 1;
    elseif loc < 1
        loc = 1;
        candidate_pool(i, :) = floor(loc) - 0.1 * K + sort(randperm(poolSize));
    else
        candidate_pool(i, :) = floor(loc) - 0.1 * K + sort(randperm(poolSize));
    end
end
candidate_pool(candidate_pool < 1 | candidate_pool > K) = K + 1;
candidate_pool = sort(candidate_pool, 2);
num_pool = sum(candidate_pool ~= K + 1, 2);

minn = zeros(1, T);
for i = 1:T
    pool = candidate_pool(i, 1:num_pool(i));
    minn(i) = min(u(pool, Tasktype(i)));
end

env.public.K = K;
env.public.T = T;
env.public.d = d;
env.public.M = M;
env.public.alpha = alpha;
env.public.beta = beta;
env.public.switchCost = SwitchCost;
env.public.taskType = Tasktype;
env.public.candidatePool = candidate_pool;
env.public.numPool = num_pool;
env.public.taskComputeWeights = Theta;
env.public.taskCommWeights = Vartheta;
env.integrationNoise = epsilon;
env.truth.x = x;
env.truth.y = y;
env.truth.R = R;
env.truth.Q = Q;
env.oracle.u = u;
env.oracle.u_cp = u_cp;
env.oracle.u_cm = u_cm;
env.oracle.u_inpro_cp = u_inpro_cp;
env.oracle.u_inpro_cm = u_inpro_cm;
env.oracle.minn = minn;
env.metadata.seed = seed;
end