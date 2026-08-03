function paths = export_allm_campaign_table(campaign)

outputDirectory = campaign.config.outputDirectory;
if ~exist(outputDirectory, 'dir')
    mkdir(outputDirectory);
end
methods = campaign.config.methods;
methodKey = cell(numel(methods), 1);
methodLabel = cell(numel(methods), 1);
regretMean = zeros(numel(methods), 1); regretStd = regretMean; regretLow = regretMean; regretHigh = regretMean;
delayMean = regretMean; delayStd = regretMean; runtimeMean = regretMean; switchMean = regretMean;
for i = 1:numel(methods)
    methodKey{i} = methods{i};
    methodLabel{i} = allm_method_label(methods{i});
    source = campaign.summary.(methods{i});
    regretMean(i) = source.finalRegret.mean; regretStd(i) = source.finalRegret.std;
    regretLow(i) = source.finalRegret.ci95(1); regretHigh(i) = source.finalRegret.ci95(2);
    delayMean(i) = source.finalDelay.mean; delayStd(i) = source.finalDelay.std;
    runtimeMean(i) = source.runtimeSeconds.mean; switchMean(i) = source.switchCount.mean;
end
methodTable = table(methodKey, methodLabel, regretMean, regretStd, regretLow, regretHigh, delayMean, delayStd, ...
    runtimeMean, switchMean);
paths.method = fullfile(outputDirectory, [campaign.runKey, '_methods.csv']);
writetable(methodTable, paths.method);

comparisons = campaign.summary.pairedEnvironmentComparisons;
keys = fieldnames(comparisons);
comparator = keys;
differenceMean = zeros(numel(keys), 1); differenceStd = differenceMean;
differenceLow = differenceMean; differenceHigh = differenceMean;
psmaWins = differenceMean; ties = differenceMean; comparatorWins = differenceMean;
for i = 1:numel(keys)
    source = comparisons.(keys{i});
    differenceMean(i) = source.statistics.mean; differenceStd(i) = source.statistics.std;
    differenceLow(i) = source.statistics.ci95(1); differenceHigh(i) = source.statistics.ci95(2);
    psmaWins(i) = source.psmaWins; ties(i) = source.ties; comparatorWins(i) = source.comparatorWins;
end
pairedTable = table(comparator, differenceMean, differenceStd, differenceLow, differenceHigh, ...
    psmaWins, ties, comparatorWins);
paths.paired = fullfile(outputDirectory, [campaign.runKey, '_paired_environment.csv']);
writetable(pairedTable, paths.paired);
end