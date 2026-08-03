function result = run_gcl_psmc_original_edge(env, config, policySeed, feedbackSeed)

rng(policySeed);
originalPath = path;
pathCleanup = onCleanup(@() restore_matlab_path(originalPath));
comparisonRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(comparisonRoot, 'common'), '-begin');
feedbackStream = RandStream('mt19937ar', 'Seed', feedbackSeed);
K = config.K; T = config.T;
L = config.gcl2c.latentDim;
N = config.gcl2c.gibbsSweeps;
knownDim = 1;
dim = knownDim + L;
X = zeros(knownDim, K);
candidatePool = env.public.candidatePool;
numPool = env.public.numPool;
taskType = env.public.taskType;
switchCost = config.switchCost;

Alg = GCLPSMCMCAlg(K, dim);
Arm = cell(1, K);
for i = 1:K
    Arm{i} = GCLPSMCMCArm(i, X, K, L);
end
[V_t, X_t, theta_t] = sample_state(Arm, Alg, X, L, K, knownDim);

epsilon = normrnd(0, 1, 1, config.simulates);
regret = 0; Regret = 0; delay = 0; Delay = 0; arm = 0;
selectedArm = zeros(1, T);
processingCost = zeros(1, T); switchTrace = zeros(1, T); totalCostTrace = zeros(1, T);
rewardTrace = zeros(1, T); decisionSeconds = zeros(1, T); updateSeconds = zeros(1, T);
recordEvery = config.recordEvery;
tickStart = tic;

for t = 1:T
    decisionTick = tic;
    m = taskType(t);
    if t ~= 1
        for sweep = 1:N
            [V_t, X_t, theta_t, Alg, Arm] = gibbs_sweep(Arm, Alg, X, L, K, knownDim, arm);
        end
    end

    np = numPool(t);
    pool = candidatePool(t, 1:np);
    scores = zeros(1, np);
    for i = 1:np
        k = pool(i);
        scores(i) = mean(logsig(theta_t' * X_t(:, k) + epsilon));
    end
    retainedIndex = [];
    if t ~= 1
        retainedIndex = find(pool == arm);
        if ~isempty(retainedIndex)
            scores(retainedIndex) = scores(retainedIndex) - switchCost;
        end
    end
    [~, index] = min(scores);
    arm = pool(index);
    selectedArm(t) = arm;
    decisionSeconds(t) = toc(decisionTick);

    updateTick = tic;
    observation = observe_allm_arm(env, config, t, arm, selectedArm(t - (t > 1)), feedbackStream);
    processingCost(t) = observation.processingCost;
    switchTrace(t) = observation.switchCost;
    totalCostTrace(t) = observation.totalCost;
    normalizedCost = processingCost(t) / (config.alpha + config.beta);
    rewardTrace(t) = normalizedCost;
    feedback = logit_clipped(normalizedCost, 1e-12);
    Alg = Alg.update(feedback, arm, X_t, K);
    Arm{arm} = Arm{arm}.update(feedback, theta_t, arm, K, knownDim);
    updateSeconds(t) = toc(updateTick);

    regret = regret + env.oracle.u(arm, m) - env.oracle.minn(t);
    delay = delay + totalCostTrace(t);
    if mod(t, recordEvery) == 0
        Regret = [Regret, regret];
        Delay = [Delay, delay];
    end
end

result.method = 'GCL-PSMC (minimally adapted)';
result.selectedArm = selectedArm;
result.Regret = Regret;
result.Delay = Delay;
result.finalRegret = regret;
result.finalDelay = delay;
result.processingCost = processingCost; result.switchCost = switchTrace;
result.totalCost = totalCostTrace; result.reward = rewardTrace;
result.decisionSeconds = decisionSeconds; result.updateSeconds = updateSeconds;
result.runtimeSeconds = toc(tickStart);
result.seed = policySeed;
result.feedbackSeed = feedbackSeed;
result.diagnostics.knownFeatureSource = 'zero_known_feature_no_id';
result.diagnostics.feedbackMapping = 'scalar_normalized_processing_cost';
result.diagnostics.actionSelection = 'cost_argmin_with_stay_bonus';
result.diagnostics.posteriorCount = 1;
end

function [latents, X_t, theta] = sample_state(arms, alg, X, latentDim, K, knownDim)
latents = zeros(latentDim, K);
for k = 1:K, latents(:, k) = arms{k}.sample(); end
X_t = zeros(knownDim + latentDim, K);
for k = 1:K, X_t(:, k) = [X(:, k); latents(:, k)]; end
theta = alg.sample();
end

function [latents, X_t, theta, alg, arms] = gibbs_sweep(arms, alg, X, latentDim, K, knownDim, arm)
[latents, X_t, theta] = sample_state(arms, alg, X, latentDim, K, knownDim);
alg = alg.update(0, arm, X_t, K);
theta = alg.sample();
for k = 1:K
    arms{k} = arms{k}.update(0, theta, arm, K, knownDim);
end
end

function restore_matlab_path(originalPath)
path(originalPath);
end