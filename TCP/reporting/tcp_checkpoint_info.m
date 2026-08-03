function info = tcp_checkpoint_info(config)
seedList=config.baseSeed+100000*(1:config.numReplicates);
if ~isfield(config,'shard') || isempty(config.shard)
    config.shard.count = 1; config.shard.index = 1;
end
assert(config.shard.count >= 1 && config.shard.index >= 1 && ...
    config.shard.index <= config.shard.count && config.shard.index == floor(config.shard.index), ...
    'tcpcmp:InvalidShard','Invalid shard specification.');
topologyP=serialize_cells(config.P);
topologyS=serialize_cells(config.S);
text=sprintf(['%s|%s|%s|T%d|K%d|d%d|entities%d|links%d|tasks%d|seed%s|noise%.17g|q%d|' ...
    'z
    'psmaG
    'granularity
    'metric
    'integration
    config.protocolVersion,config.implementationVersion,config.name,config.T,config.K,config.d, ...
    config.numEntities,config.numLinksPerPath,config.numTaskTypes,mat2str(seedList), ...
    config.feedbackNoiseStd,config.oracleQuadraturePoints,config.z,config.alpha,config.beta,config.gamma, ...
    mat2str(config.Weight),config.totalPathWeight,topologyP,mat2str(config.index),topologyS,config.recordEvery,config.simulates, ...
    config.psma.gibbsSweeps,config.psma.priorPrecision,config.gcl.gibbsSweeps,config.gcl.latentDim, ...
    config.gcl.priorPrecision,config.glmucb.delta,strjoin(config.methods,','),config.objectiveSemantics, ...
    config.actionSelectionDirection,config.feedbackGranularity,config.feedbackNoiseSchema, ...
    config.contextVariant,config.contextDimension,config.rewardOrCostScale,config.oracleDefinition, ...
    config.expectationMethod,config.metricSchemaVersion,config.canonicalMetric,config.tieBreakRule, ...
    config.switchCost,config.feedbackEpsilon,config.poolFraction,config.methodImplementationVersion, ...
    config.integrationNoiseReusePolicy,config.feedbackPairingPolicy, ...
    config.globalIdIndexingVersion,config.legacyPathPolicy);
info.seedList=seedList; info.fingerprint=simple_fingerprint(text);
info.runKey=sprintf('T%d_K%d_d%d_g%d_n%d_%s',config.T,config.K,config.d,config.gcl.gibbsSweeps,config.numReplicates,info.fingerprint);
info.conditionDirectory=fullfile(config.outputDirectory,'campaigns',config.campaignId, ...
    ['condition_',info.runKey,shard_suffix(config.shard)]);
info.checkpointPath=fullfile(info.conditionDirectory,'comparison_checkpoint.mat'); info.tempPath=fullfile(info.conditionDirectory,'comparison_checkpoint.tmp.mat');
info.completePath=fullfile(info.conditionDirectory,'comparison_complete.mat'); info.completeTempPath=fullfile(info.conditionDirectory,'comparison_complete.tmp.mat');
info.shardIndices=find(mod((1:config.numReplicates)-1,config.shard.count)==config.shard.index-1);
end
function suffix=shard_suffix(shard)
if shard.count > 1
    suffix=sprintf('_shard%dof%d',shard.index,shard.count);
else
    suffix='';
end
end
function text=serialize_cells(values)
parts=cellfun(@mat2str,values,'UniformOutput',false);
text=strjoin(parts,';');
end
function fingerprint=simple_fingerprint(text)
values=double(text); modulus=4294967296; accumulator=0;
for i=1:numel(values), accumulator=mod(accumulator*257+values(i),modulus); end
fingerprint=lower(dec2hex(uint32(accumulator),8));
end