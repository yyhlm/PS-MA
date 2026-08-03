function suite = run_allm_scenario_suite(baseConfig, selection)

if nargin < 1 || isempty(baseConfig)
    baseConfig = allm_config();
end
if nargin < 2 || isempty(selection)
    selection = 'comparisons';
end
registry = allm_scenario_registry(baseConfig);
suite.selection = selection;
suite.registry = registry;
suite.completedAt = '';

switch selection
    case 'comparisons'
        entries = registry.comparisons;
        suite.conditions = run_comparison_entries(entries);
    case 'psma_sweeps'
        entries = registry.psmaSweeps;
        suite.conditions = run_sweep_entries(entries);
    otherwise
        error('allm:UnknownScenarioSuite', 'Unknown suite selection: %s', selection);
end
suite.completedAt = char(datetime('now', 'Format', "yyyy-MM-dd'T'HH:mm:ss"));
suite.path = save_suite(suite, baseConfig, selection);
suite.csvPath = export_allm_scenario_suite(suite, baseConfig.outputDirectory);
if baseConfig.makeFigures
    suite.figurePaths = plot_allm_scenario_suite(suite, baseConfig.outputDirectory);
else
    suite.figurePaths = struct();
end
end

function conditions = run_comparison_entries(entries)
conditions = struct('id', {}, 'sourceExperiment', {}, 'campaign', {});
for i = 1:numel(entries)
    campaign = run_allm_campaign(entries(i).config);
    conditions(i).id = entries(i).id;
    conditions(i).sourceExperiment = entries(i).sourceExperiment;
    conditions(i).campaign = campaign;
end
end

function conditions = run_sweep_entries(entries)
conditions = struct('id', {}, 'dimension', {}, 'gibbsSweeps', {}, 'campaign', {});
for i = 1:numel(entries)
    campaign = run_allm_campaign(entries(i).config);
    conditions(i).id = entries(i).id;
    conditions(i).dimension = entries(i).dimension;
    conditions(i).gibbsSweeps = entries(i).gibbsSweeps;
    conditions(i).campaign = campaign;
end
end

function path = save_suite(suite, baseConfig, selection)
outputDirectory = baseConfig.outputDirectory;
if ~exist(outputDirectory, 'dir')
    mkdir(outputDirectory);
end
info = allm_checkpoint_info(baseConfig);
fileName = sprintf('allm_edge_%s_suite_n%d_%s.mat', selection, ...
    baseConfig.numReplicates, info.fingerprint);
path = fullfile(outputDirectory, fileName);
save(path, 'suite', '-v7.3');
end