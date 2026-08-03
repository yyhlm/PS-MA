function config = tcp_four_method_config()

config = default_config();
config.name = 'tcp_native_five_method';
config.protocolVersion = 'tcp_native_minimal_gcl_cost_consistent_v5_seeded_gcl';
config.implementationVersion = 'tcp_native_minimal_gcl_seeded_glmucb_task_plus_id_v7';
config.T = 2000;
config.recordEvery = 20;
config.numReplicates = 1000;
config.methodImplementationVersion = 'tcp_single_posterior_minimal_gcl_seeded_glmucb_task_plus_id_v7';
config.methods = {'psma', 'hlinucb', 'tsicf', 'gcl', 'glmucb'};
config.campaignId = 'tcp_native_five_method_seeded_gcl_T2000_n1000';
config.publishResults = true;
config.makeFigures = true;
end