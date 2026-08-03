function comparison = run_comparison(config)

if ~isfield(config,'shard') || isempty(config.shard)
    config.shard.count = 1;
    config.shard.index = 1;
end
info=tcp_checkpoint_info(config);
if config.checkpointEnabled && ~exist(info.conditionDirectory,'dir'), mkdir(info.conditionDirectory); end
if config.checkpointEnabled && ~config.resume && ...
        (exist(info.checkpointPath,'file') || exist(info.completePath,'file'))
    error('tcpcmp:ExistingCampaignData', ...
        'Campaign data already exists while resume is disabled. Use a new campaign ID.');
end
if config.checkpointEnabled && config.resume && exist(info.completePath,'file')
    loaded=load(info.completePath,'comparison'); comparison=loaded.comparison; validate_complete(comparison,config,info); return;
end
checkpoint=initialize_checkpoint(config,info);
if config.checkpointEnabled && config.resume && exist(info.checkpointPath,'file')
    loaded=load(info.checkpointPath,'checkpoint'); checkpoint=loaded.checkpoint; validate_checkpoint(checkpoint,config,info);
end
owned=info.shardIndices;
newlyCompleted=0;
for r=owned
    if checkpoint.completedMask(r), continue; end
    checkpoint.results{r}=run_tcp_replicate(config,r); checkpoint.completedMask(r)=true; newlyCompleted=newlyCompleted+1;
    if config.checkpointEnabled && (newlyCompleted>=config.checkpointEveryReplicates || all(checkpoint.completedMask(owned)))
        checkpoint.lastUpdated=char(datetime('now','Format',"yyyy-MM-dd'T'HH:mm:ss"));
        save(info.tempPath,'checkpoint','-v7.3'); tcp_same_directory_replace(info.tempPath,info.checkpointPath); newlyCompleted=0;
    end
end
if config.shard.count > 1
    comparison=checkpoint;
    comparison.config=config;
    comparison.shard=config.shard;
    return;
end
comparison.schemaVersion='tcp_comparison_v1'; comparison.campaignId=config.campaignId; comparison.configFingerprint=info.fingerprint;
comparison.runKey=info.runKey; comparison.config=config; comparison.results=checkpoint.results;
comparison.summary=summarize_tcp_comparison(checkpoint.results,config); comparison.seedList=info.seedList;
comparison.metricSchemaVersion=config.metricSchemaVersion; comparison.canonicalMetric=config.canonicalMetric;
comparison.completedAt=char(datetime('now','Format',"yyyy-MM-dd'T'HH:mm:ss")); validate_complete(comparison,config,info);
if config.checkpointEnabled, save(info.completeTempPath,'comparison','-v7.3'); tcp_same_directory_replace(info.completeTempPath,info.completePath); end
if config.publishResults, tcp_save_comparison_result(comparison); export_tcp_comparison_table(comparison); end
if config.makeFigures, plot_tcp_comparison(comparison); end
end
function checkpoint=initialize_checkpoint(config,info)
checkpoint.schemaVersion='tcp_checkpoint_v1'; checkpoint.campaignId=config.campaignId; checkpoint.protocolVersion=config.protocolVersion;
checkpoint.implementationVersion=config.implementationVersion; checkpoint.configFingerprint=info.fingerprint; checkpoint.seedList=info.seedList;
checkpoint.completedMask=false(1,config.numReplicates); checkpoint.results=cell(1,config.numReplicates); checkpoint.lastUpdated='';
end
function validate_checkpoint(checkpoint,config,info)
assert(strcmp(checkpoint.campaignId,config.campaignId),'tcpcmp:CheckpointMismatch','Campaign differs.');
assert(strcmp(checkpoint.configFingerprint,info.fingerprint),'tcpcmp:CheckpointMismatch','Configuration differs.');
assert(isequal(checkpoint.seedList,info.seedList),'tcpcmp:CheckpointMismatch','Seed list differs.');
end
function validate_complete(comparison,config,info)
assert(strcmp(comparison.campaignId,config.campaignId),'tcpcmp:CompleteMismatch','Campaign differs.');
assert(strcmp(comparison.configFingerprint,info.fingerprint),'tcpcmp:CompleteMismatch','Configuration differs.');
assert(isequal(comparison.seedList,info.seedList),'tcpcmp:CompleteMismatch','Seed list differs.');
assert(isequal(comparison.config.methods,config.methods),'tcpcmp:CompleteMismatch','Method list differs.');
assert(numel(comparison.results)==config.numReplicates && all(~cellfun(@isempty,comparison.results)),'tcpcmp:CompleteMismatch','Result set incomplete.');
end