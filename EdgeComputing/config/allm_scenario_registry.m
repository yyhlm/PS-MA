function registry = allm_scenario_registry(baseConfig)

if nargin < 1 || isempty(baseConfig)
    baseConfig = allm_config();
end
registry.reportingManifest.mainText = {'edge_default', 'edge_beta_2', ...
    'edge_servers_20', 'edge_servers_80', 'edge_tasks_2', 'edge_tasks_10'};
registry.reportingManifest.supplementary = {'edge_switch_001', 'edge_switch_004'};
registry.reportingManifest.validationOnly = {'onepath_no_id'};

registry.comparisons = make_comparisons(baseConfig);
registry.psmaSweeps = struct('id', {}, 'dimension', {}, 'gibbsSweeps', {}, 'config', {});
end

function scenarios = make_comparisons(base)
scenarios = struct('id', {}, 'sourceExperiment', {}, 'config', {});
scenarios(end + 1) = scenario(base, 'edge_default', 'All', 'allm_edge_default_n1000', 1000);

config = base; config.beta = 2;
scenarios(end + 1) = scenario(config, 'edge_beta_2', 'Exp2', 'allm_edge_beta2_n1000', 1000);
config = base; config.switchCost = 0.01;
scenarios(end + 1) = scenario(config, 'edge_switch_001', 'Exp2', 'allm_edge_switch001_n1000', 1000);
config = base; config.switchCost = 0.04;
scenarios(end + 1) = scenario(config, 'edge_switch_004', 'Exp2', 'allm_edge_switch004_n1000', 1000);

config = base; config.K = 20;
scenarios(end + 1) = scenario(config, 'edge_servers_20', 'Exp3', 'allm_edge_k20_n1000', 1000);
config = base; config.K = 80;
scenarios(end + 1) = scenario(config, 'edge_servers_80', 'Exp3', 'allm_edge_k80_n1000', 1000);

config = base; config.M = 2;
scenarios(end + 1) = scenario(config, 'edge_tasks_2', 'Exp4', 'allm_edge_m2_n1000', 1000);
config = base; config.M = 10;
scenarios(end + 1) = scenario(config, 'edge_tasks_10', 'Exp4', 'allm_edge_m10_n1000', 1000);
end

function sweeps = make_psma_sweeps(base)
sweeps = struct('id', {}, 'dimension', {}, 'gibbsSweeps', {}, 'config', {});
for d = [5, 10]
    for n = [10, 50, 100, 500]
        config = base;
        config.d = d;
        config.gcl2c.latentDim = d;
        config.methods = {'psma'};
        config.psma.gibbsSweeps = n;
        config.campaignId = sprintf('allm_edge_exp1_d%d_n%d_r1000', d, n);
        entry.id = sprintf('edge_psma_d%d_n%d', d, n);
        entry.dimension = d;
        entry.gibbsSweeps = n;
        entry.config = config;
        sweeps(end + 1) = entry;
    end
end
end

function entry = scenario(config, id, sourceExperiment, campaignId, numReplicates)
config.campaignId = campaignId;
config.numReplicates = numReplicates;
entry.id = id;
entry.sourceExperiment = sourceExperiment;
entry.config = config;
end