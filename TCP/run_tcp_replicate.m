function replicate = run_tcp_replicate(config, index)

seedPlan = make_tcp_seed_plan(config.baseSeed, index);
env = make_tcp_environment(config, seedPlan.environment);
validate_tcp_environment(env, config);
oracle = solve_tcp_oracle(env, config);
replicate.environment = env;
replicate.oracle = oracle;
replicate.seedPlan = seedPlan;
replicate.replicateIndex = index;
replicate.seed = seedPlan.environment;
for m = 1:numel(config.methods)
    method = config.methods{m};
    switch method
        case 'psma'
            result = run_psma_tcp(env, config, seedPlan.psma);
        case 'hlinucb'
            result = run_hlinucb_tcp(env, config, seedPlan.hlinucb);
        case 'tsicf'
            result = run_tsicf_tcp(env, config, seedPlan.tsicf);
        case 'gcl'
            result = run_gcl_psmc_original_tcp(env, config, seedPlan.gcl);
        case 'glmucb'
            result = run_glmucb_tcp(env, config, seedPlan.glmucb);
        otherwise
            error('tcpcmp:UnknownMethod', 'Unknown method: %s', method);
    end
    replicate.(method) = result;
    replicate.([method, 'Metrics']) = evaluate_tcp_metrics(result, env, oracle, config);
end
end