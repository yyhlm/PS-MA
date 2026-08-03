function path = save_allm_campaign_result(campaign)

outputDirectory = campaign.config.outputDirectory;
if ~exist(outputDirectory, 'dir')
    mkdir(outputDirectory);
end
path = fullfile(outputDirectory, [campaign.runKey, '.mat']);
save(path, 'campaign', '-v7.3');
end