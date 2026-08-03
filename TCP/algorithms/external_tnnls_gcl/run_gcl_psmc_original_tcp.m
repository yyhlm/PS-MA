function result = run_gcl_psmc_original_tcp(env, config, seeds)

rng(seeds.policy);
stream = RandStream('mt19937ar', 'Seed', seeds.policy);
originalPath = current_matlab_path();
pathCleanup = onCleanup(@() restore_matlab_path(originalPath));
comparisonRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(comparisonRoot, 'common'), '-begin');
feedbackStream = RandStream('mt19937ar', 'Seed', seeds.feedback);
K = config.K; T = config.T;
L = config.gcl.latentDim;
N = config.gcl.gibbsSweeps;
knownDim = 1;
X = zeros(knownDim, K);
knownFeatureSource = 'zero_known_feature_no_id';
dim = knownDim + L;

Alg = GCLPSMCMCAlg(K, dim);
Arm = cell(1, K);
for i = 1:K
    Arm{i} = GCLPSMCMCArm(i, X, K, L);
end
[V_t, X_t, theta_t] = sample_state(Arm, Alg, X, L, K, knownDim);

epsilon = randn(stream, 1, config.simulates);
regret = 0; Regret = 0; delay = 0; Delay = 0; previousPath = 0;
selectedArm = zeros(1, T);
processingCost = zeros(1, T); switchCost = zeros(1, T); totalCost = zeros(1, T);
reward = zeros(1, T); decisionSeconds = zeros(1, T); updateSeconds = zeros(1, T);
recordEvery = config.recordEvery;
tickStart = tic;

for t = 1:T
    decisionTick = tic;
    if t ~= 1
        for sweep = 1:N
            [V_t, X_t, theta_t, Alg, Arm] = gibbs_sweep(Arm, Alg, X, L, K, knownDim, previousPath);
        end
    end
    scores = zeros(1, K);
    for path = 1:K
        scores(path) = mean(logsig(theta_t' * X_t(:, path) + epsilon));
    end
    [~, path] = min(scores);
    selectedArm(t) = path;
    decisionSeconds(t) = toc(decisionTick);

    updateTick = tic;
    observation = observe_selected_arm_tcp(env, config, feedbackStream, t, path, previousPath);
    normalizedCost = observation.processingCost / config.totalPathWeight;
    processingCost(t) = observation.processingCost; totalCost(t) = observation.totalCost;
    reward(t) = config.totalPathWeight - observation.processingCost;
    feedback = logit_clipped(normalizedCost, config.feedbackEpsilon);
    Alg = Alg.update(feedback, path, X_t, K);
    Arm{path} = Arm{path}.update(feedback, theta_t, path, K, knownDim);
    updateSeconds(t) = toc(updateTick);

    delay = delay + observation.processingCost;
    regret = regret + env.oracle.expectedProcessingCost(path, t) - min(env.oracle.expectedProcessingCost(:, t));
    if mod(t, recordEvery) == 0
        Regret = [Regret, regret];
        Delay = [Delay, delay];
    end
    previousPath = path;
end

result.method = 'GCL-PSMC (minimally adapted)';
result.selectedArm = selectedArm;
result.Regret = Regret;
result.Delay = Delay;
result.finalRegret = regret;
result.finalDelay = delay;
result.processingCost = processingCost; result.switchCost = switchCost; result.totalCost = totalCost;
result.reward = reward; result.decisionSeconds = decisionSeconds; result.updateSeconds = updateSeconds;
result.runtimeSeconds = toc(tickStart);
result.seed = seeds.policy;
result.policySeed = seeds.policy;
result.feedbackSeed = seeds.feedback;
result.diagnostics.knownFeatureSource = knownFeatureSource;
result.diagnostics.knownFeatureDimension = knownDim;
result.diagnostics.feedbackMapping = 'scalar_normalized_path_cost';
result.diagnostics.actionSelection = 'cost_argmin';
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

function value = current_matlab_path()
value = path;
end