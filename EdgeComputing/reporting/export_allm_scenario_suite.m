function path = export_allm_scenario_suite(suite, outputDirectory)

if ~exist(outputDirectory, 'dir')
    mkdir(outputDirectory);
end
conditionId = {};
sourceExperiment = {};
methodKey = {};
methodLabel = {};
finalRegretMean = [];
finalRegretStd = [];
for i = 1:numel(suite.conditions)
    campaign = suite.conditions(i).campaign;
    methods = campaign.config.methods;
    for j = 1:numel(methods)
        key = methods{j};
        conditionId{end + 1, 1} = suite.conditions(i).id;
        if isfield(suite.conditions, 'sourceExperiment')
            sourceExperiment{end + 1, 1} = suite.conditions(i).sourceExperiment;
        else
            sourceExperiment{end + 1, 1} = 'Exp1';
        end
        methodKey{end + 1, 1} = key;
        if strcmp(key, 'psma') && isfield(suite.conditions, 'gibbsSweeps')
            methodLabel{end + 1, 1} = sprintf('PS-MA (N=%d)', suite.conditions(i).gibbsSweeps);
        else
            methodLabel{end + 1, 1} = allm_method_label(key);
        end
        finalRegretMean(end + 1, 1) = campaign.summary.(key).finalRegret.mean;
        finalRegretStd(end + 1, 1) = campaign.summary.(key).finalRegret.std;
    end
end
rows = table(conditionId, sourceExperiment, methodKey, methodLabel, finalRegretMean, finalRegretStd);
path = fullfile(outputDirectory, ['allm_edge_', suite.selection, '_summary.csv']);
writetable(rows, path);
end