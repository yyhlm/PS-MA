function campaign = merge_allm_shards(config, shardCount)

assert(nargin == 2, 'allm:InvalidArgs', 'Usage: merge_allm_shards(config, shardCount)');
config.shard.count = 1;
config.shard.index = 1;
info = allm_checkpoint_info(config);
if ~exist(info.conditionDirectory, 'dir')
    mkdir(info.conditionDirectory);
end

merged = initialize_checkpoint(config, info);
covered = false(1, config.numReplicates);
for s = 1:shardCount
    shardConfig = config;
    shardConfig.shard.count = shardCount;
    shardConfig.shard.index = s;
    shardInfo = allm_checkpoint_info(shardConfig);
    assert(exist(shardInfo.checkpointPath, 'file') == 2, ...
        'allm:MissingShard', 'Shard %d checkpoint not found: %s', s, shardInfo.checkpointPath);
    loaded = load(shardInfo.checkpointPath, 'checkpoint');
    shard = loaded.checkpoint;
    validate_allm_campaign(shard, shardConfig, shardInfo, false);
    for k = shardInfo.shardIndices
        assert(~merged.completedMask(k), 'allm:DuplicateSeed', ...
            'Seed
        merged.results{k} = shard.results{k};
        merged.completedMask(k) = true;
        covered(k) = true;
    end
end
assert(all(covered), 'allm:IncompleteCoverage', ...
    'Shards do not cover all seeds. Missing:
    strjoin(arrayfun(@num2str, find(~covered), 'UniformOutput', false), ','));
merged.lastUpdated = timestamp();

campaign.schemaVersion = config.completeSchemaVersion;
campaign.campaignId = config.campaignId;
campaign.protocolVersion = config.protocolVersion;
campaign.implementationVersion = config.implementationVersion;
campaign.configFingerprint = info.fingerprint;
campaign.runKey = info.runKey;
campaign.config = config;
campaign.seedList = info.seedList;
campaign.completedMask = merged.completedMask;
campaign.results = merged.results;
campaign.summary = summarize_allm_campaign(merged.results, config);
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

function text = timestamp()
text = char(datetime('now', 'Format', "yyyy-MM-dd'T'HH:mm:ss"));
end