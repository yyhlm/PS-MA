function registry = tcp_scenario_registry(baseConfig)

if nargin < 1 || isempty(baseConfig)
    baseConfig = tcp_four_method_config();
end
registry.psmaSweeps = struct('id', {}, 'dimension', {}, 'gibbsSweeps', {}, 'config', {});
registry.comparisons = make_comparisons(baseConfig);
end

function scenarios = make_comparisons(base)
scenarios = struct('id', {}, 'sourceExperiment', {}, 'config', {});

config = with_z(base, 0.5);
scenarios(end + 1) = scenario(config, 'tcp_z05', 'Exp2', 'tcp_native_z05_m5_n1000', 1000);
config = with_z(base, 2);
scenarios(end + 1) = scenario(config, 'tcp_z2', 'Exp2', 'tcp_native_z2_m5_n1000', 1000);

config = base;
config.numTaskTypes = 2;
scenarios(end + 1) = scenario(config, 'tcp_m2', 'Exp4', 'tcp_native_z1_m2_n1000', 1000);
config.numTaskTypes = 10;
scenarios(end + 1) = scenario(config, 'tcp_m10', 'Exp4', 'tcp_native_z1_m10_n1000', 1000);
end

function config = with_z(base, z)
config = base;
config.z = z;
config.beta = 2 ^ z;
config.gamma = 4 ^ z;
config.Weight = [config.alpha, config.beta, config.gamma, ...
    config.gamma, config.beta, config.alpha];
config.totalPathWeight = sum(config.Weight);
end

function entry = scenario(config, id, sourceExperiment, campaignId, numReplicates)
config.campaignId = campaignId;
config.numReplicates = numReplicates;
entry.id = id;
entry.sourceExperiment = sourceExperiment;
entry.config = config;
end