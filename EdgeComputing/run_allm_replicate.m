function results = run_allm_replicate(config, replicateIndex)

assert(isscalar(replicateIndex) && replicateIndex >= 1 && ...
    replicateIndex == floor(replicateIndex), 'allm:InvalidReplicate', ...
    'Replicate index must be a positive integer.');
seedPlan.environment = config.baseSeed + 100000 * replicateIndex;
methods = config.methods;
methodPolicyOffset = containers.Map({'psma', 'hlinucb', 'tsicf', 'gcl2c', 'glmucb'}, ...
    [1100, 1200, 1300, 1400, 1500]);
methodFeedbackOffset = containers.Map({'psma', 'hlinucb', 'tsicf', 'gcl2c', 'glmucb'}, ...
    [5100, 5200, 5300, 5400, 5500]);
for m = 1:numel(methods)
    method = methods{m};
    assert(methodPolicyOffset.isKey(method), 'allm:UnknownMethod', ...
        'Unknown method:
    seedPlan.(method).policy = seedPlan.environment + methodPolicyOffset(method);
    seedPlan.(method).feedback = seedPlan.environment + methodFeedbackOffset(method);
end

env = make_allm_environment(config, seedPlan.environment);
results.env = env;
results.replicateIndex = replicateIndex;
results.envSeed = seedPlan.environment;
results.seedPlan = seedPlan;

for m = 1:numel(methods)
    method = methods{m};
    seeds = seedPlan.(method);
    switch method
        case 'psma'
            result = run_psma_allm(env, config, seeds.policy, seeds.feedback);
        case 'hlinucb'
            result = run_hlinucb_allm(env, config, seeds.policy, seeds.feedback);
        case 'tsicf'
            result = run_tsicf_allm(env, config, seeds.policy, seeds.feedback);
        case 'gcl2c'
            result = run_gcl_psmc_original_edge(env, config, seeds.policy, seeds.feedback);
        case 'glmucb'
            result = run_glmucb_allm(env, config, seeds.policy, seeds.feedback);
    end
    results.(method) = result;
    if config.verbose
        fprintf('  replicate %d %s: finalRegret=%.4f, runtime=%.1fs\n', ...
            replicateIndex, method, result.finalRegret, result.runtimeSeconds);
    end
end
end