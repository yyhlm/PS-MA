function campaign = run_allm_campaign(config)

validate_config(config);
info = allm_checkpoint_info(config);
if ~exist(info.conditionDirectory, 'dir')
    mkdir(info.conditionDirectory);
end
remove_if_present(info.tempPath);
remove_if_present(info.completeTempPath);

if exist(info.completePath, 'file')
    if ~config.resume
        error('allm:ExistingCampaignData', ...
            'Complete campaign exists while resume is disabled. Use a new campaign ID.');
    end
    loaded = load(info.completePath, 'campaign');
    campaign = loaded.campaign;
    validate_allm_campaign(campaign, config, info, true);
    publish_artifacts(campaign, config);
    return;
end
if ~config.resume && exist(info.checkpointPath, 'file')
    error('allm:ExistingCampaignData', ...
        'Checkpoint exists while resume is disabled. Use a new campaign ID.');
end

checkpoint = initialize_checkpoint(config, info);
if config.resume && exist(info.checkpointPath, 'file')
    loaded = load(info.checkpointPath, 'checkpoint');
    checkpoint = loaded.checkpoint;
    validate_allm_campaign(checkpoint, config, info, false);
end
owned = info.shardIndices;
pending = setdiff(owned, find(checkpoint.completedMask));
newlyCompleted = 0;
while ~isempty(pending)
    batchSize = min(config.checkpointEveryReplicates, numel(pending));
    indices = pending(1:batchSize);
    batch = execute_batch(config, indices);
    for i = 1:numel(indices)
        index = indices(i);
        checkpoint.results{index} = batch{i};
        checkpoint.completedMask(index) = true;
        newlyCompleted = newlyCompleted + 1;
    end
    pending = setdiff(owned, find(checkpoint.completedMask));
    if newlyCompleted >= config.checkpointEveryReplicates || isempty(pending)
        checkpoint.lastUpdated = timestamp();
        save(info.tempPath, 'checkpoint', '-v7.3');
        same_directory_replace(info.tempPath, info.checkpointPath);
        newlyCompleted = 0;
    end
end

if info.shard.count > 1
    checkpoint.shard = info.shard;
    save(info.tempPath, 'checkpoint', '-v7.3');
    same_directory_replace(info.tempPath, info.checkpointPath);
    campaign = checkpoint;
    campaign.config = config;
    return;
end

campaign.schemaVersion = config.completeSchemaVersion;
campaign.campaignId = config.campaignId;
campaign.protocolVersion = config.protocolVersion;
campaign.implementationVersion = config.implementationVersion;
campaign.configFingerprint = info.fingerprint;
campaign.runKey = info.runKey;
campaign.config = config;
campaign.seedList = info.seedList;
campaign.completedMask = checkpoint.completedMask;
campaign.results = checkpoint.results;
campaign.summary = summarize_allm_campaign(checkpoint.results, config);
campaign.completedAt = timestamp();
validate_allm_campaign(campaign, config, info, true);
save(info.completeTempPath, 'campaign', '-v7.3');
same_directory_replace(info.completeTempPath, info.completePath);
publish_artifacts(campaign, config);
end

function checkpoint = initialize_checkpoint(config, info)
checkpoint.schemaVersion = config.checkpointSchemaVersion;
checkpoint.campaignId = config.campaignId;
checkpoint.protocolVersion = config.protocolVersion;
checkpoint.implementationVersion = config.implementationVersion;
checkpoint.configFingerprint = info.fingerprint;
checkpoint.runKey = info.runKey;
checkpoint.config = config;
checkpoint.seedList = info.seedList;
checkpoint.completedMask = false(1, config.numReplicates);
checkpoint.results = cell(1, config.numReplicates);
checkpoint.lastUpdated = '';
end

function results = execute_batch(config, indices)
results = cell(1, numel(indices));
if config.useParallel
    pool = gcp('nocreate');
    assert(~isempty(pool), 'allm:NoParallelPool', ...
        'useParallel requires an already-open parallel pool.');
    workerConfig = config;
    workerConfig.verbose = false;
    parfor i = 1:numel(indices)
        results{i} = run_allm_replicate(workerConfig, indices(i));
    end
else
    for i = 1:numel(indices)
        results{i} = run_allm_replicate(config, indices(i));
    end
end
end

function publish_artifacts(campaign, config)
if config.exportResults
    save_allm_campaign_result(campaign);
    export_allm_campaign_table(campaign);
end
if config.makeFigures
    plot_allm_campaign(campaign);
end
end

function validate_config(config)
assert(config.T >= 1 && config.T == floor(config.T), 'allm:InvalidConfig', ...
    'T must be a positive integer.');
assert(config.K >= 10 && config.K == floor(config.K), 'allm:InvalidConfig', ...
    'K must be an integer of at least 10 for the All.m candidate pool.');
assert(config.d >= 1 && config.M >= 1 && config.numReplicates >= 1, ...
    'allm:InvalidConfig', 'Dimensions and replicate count must be positive.');
assert(config.recordEvery >= 1 && config.recordEvery == floor(config.recordEvery) && ...
    mod(config.T, config.recordEvery) == 0, 'allm:InvalidConfig', ...
    'recordEvery must be a positive divisor of T.');
assert(config.checkpointEveryReplicates >= 1 && ...
    config.checkpointEveryReplicates == floor(config.checkpointEveryReplicates), ...
    'allm:InvalidConfig', 'Checkpoint interval must be a positive integer.');
assert(isequal(config.methods, unique(config.methods, 'stable')), 'allm:InvalidConfig', ...
    'Method names must be unique.');
end

function remove_if_present(path)
if exist(path, 'file')
    delete(path);
end
end

function text = timestamp()
text = char(datetime('now', 'Format', "yyyy-MM-dd'T'HH:mm:ss"));
end