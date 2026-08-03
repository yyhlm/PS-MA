function comparison = merge_tcp_shards(config, shardCount)

assert(shardCount >= 1 && shardCount == floor(shardCount), ...
    'tcpcmp:InvalidShard', 'Shard count must be a positive integer.');
config.shard.count = 1;
config.shard.index = 1;
info = tcp_checkpoint_info(config);
merged = initialize_checkpoint(config, info);
covered = false(1, config.numReplicates);
for s = 1:shardCount
    shardConfig = config;
    shardConfig.shard.count = shardCount;
    shardConfig.shard.index = s;
    shardInfo = tcp_checkpoint_info(shardConfig);
    assert(exist(shardInfo.checkpointPath, 'file') == 2, ...
        'tcpcmp:MissingShard', 'Missing TCP shard %d.', s);
    loaded = load(shardInfo.checkpointPath, 'checkpoint');
    shard = loaded.checkpoint;
    assert(strcmp(shard.configFingerprint, info.fingerprint), ...
        'tcpcmp:ShardMismatch', 'TCP shard fingerprint differs.');
    for index = shardInfo.shardIndices
        assert(~covered(index) && shard.completedMask(index), ...
            'tcpcmp:DuplicateOrIncompleteShard', 'Invalid shard coverage at seed %d.', index);
        merged.results{index} = shard.results{index};
        merged.completedMask(index) = true;
        covered(index) = true;
    end
end
assert(all(covered), 'tcpcmp:IncompleteCoverage', 'TCP shards do not cover all seeds.');
comparison.schemaVersion = 'tcp_comparison_v1';
comparison.campaignId = config.campaignId;
comparison.configFingerprint = info.fingerprint;
comparison.runKey = info.runKey;
comparison.config = config;
comparison.results = merged.results;
comparison.summary = summarize_tcp_comparison(merged.results, config);
comparison.seedList = info.seedList;
comparison.metricSchemaVersion = config.metricSchemaVersion;
comparison.canonicalMetric = config.canonicalMetric;
comparison.completedAt = char(datetime('now', 'Format', "yyyy-MM-dd'T'HH:mm:ss"));
config.shard.count = 1;
config.shard.index = 1;
comparison.config = config;
if config.checkpointEnabled
    if ~exist(info.conditionDirectory, 'dir'), mkdir(info.conditionDirectory); end
    save(info.completeTempPath, 'comparison', '-v7.3');
    tcp_same_directory_replace(info.completeTempPath, info.completePath);
end
if config.publishResults
    tcp_save_comparison_result(comparison);
    export_tcp_comparison_table(comparison);
end
if config.makeFigures, plot_tcp_comparison(comparison); end
end

function checkpoint = initialize_checkpoint(config, info)
checkpoint.schemaVersion = 'tcp_checkpoint_v1';
checkpoint.campaignId = config.campaignId;
checkpoint.protocolVersion = config.protocolVersion;
checkpoint.implementationVersion = config.implementationVersion;
checkpoint.configFingerprint = info.fingerprint;
checkpoint.seedList = info.seedList;
checkpoint.completedMask = false(1, config.numReplicates);
checkpoint.results = cell(1, config.numReplicates);
checkpoint.lastUpdated = '';
end