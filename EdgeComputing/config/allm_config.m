function config = allm_config()

config.name = 'allm_native';
config.protocolVersion = 'allm_native_v4_cost_consistent_gcl';
config.implementationVersion = 'allm_native_campaign_v8_cost_consistent_gcl_glmucb_task_plus_id';
config.methodImplementationVersion = 'allm_native_methods_v7_glmucb_task_plus_id';
config.checkpointSchemaVersion = 'allm_native_checkpoint_v1';
config.completeSchemaVersion = 'allm_native_complete_v1';
config.T = 2000;
config.K = 50;
config.d = 10;
config.M = 5;
config.alpha = 1;
config.beta = 1;
config.switchCost = 0.02;
config.lambda = 1;
config.simulates = 10000;
config.recordEvery = floor(config.T / 100);

config.numReplicates = 1000;
config.baseSeed = 20260716;

config.contextVariant = 'gcl_zero_known_feature_no_id';
config.actionSelectionDirection = 'native_method_specific';
config.tieBreakRule = 'matlab_first_minimum';
config.channelInterpretation = 'psma_hlinucb_tsicf_native_two_channel;gcl_single_normalized_total_cost_feedback';
config.oracleDefinition = 'per_round_greedy_processing_cost_minn';
config.regretDefinition = 'cumulative_processing_cost_regret';
config.integrationNoiseReusePolicy = 'environment_noise_reused_by_psma';
config.feedbackPairingPolicy = 'shared_environment_independent_method_feedback';
config.globalIdIndexingVersion = 'global_candidate_server_id_v1';

config.psma.gibbsSweeps = 50;
config.gcl2c.gibbsSweeps = 50;
config.gcl2c.latentDim = config.d;
config.gcl2c.priorPrecision = 1.0;
config.glmucb.delta = 0.01;

config.methods = {'psma', 'hlinucb', 'tsicf', 'gcl2c', 'glmucb'};

config.oracle = 'per_round_greedy_minn';
config.feedback = 'per_round_normrnd';
config.regretMetric = 'greedy_cost_regret';

config.outputDirectory = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results');
config.campaignId = 'allm_native_main_n1000';
config.checkpointEveryReplicates = 1;
config.resume = true;
config.useParallel = false;
config.verbose = true;
config.exportResults = true;
config.makeFigures = true;
config.canonicalMetric = 'greedy_cost_regret';
end