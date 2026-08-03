function info = allm_checkpoint_info(config)

assert(~isempty(regexp(config.campaignId, '^[A-Za-z0-9][A-Za-z0-9._-]*$', 'once')), ...
    'allm:InvalidCampaignId', 'Campaign ID contains invalid characters.');
if ~isfield(config, 'shard') || isempty(config.shard) || ...
        ~isfield(config.shard, 'count') || isempty(config.shard.count)
    config.shard.count = 1;
end
if ~isfield(config.shard, 'index') || isempty(config.shard.index)
    config.shard.index = 1;
end
assert(config.shard.count >= 1 && config.shard.count == floor(config.shard.count), ...
    'allm:InvalidShard', 'shard.count must be a positive integer.');
assert(config.shard.index >= 1 && config.shard.index <= config.shard.count, ...
    'allm:InvalidShard', 'shard.index must be in [1, shard.count].');
info.shard.count = config.shard.count;
info.shard.index = config.shard.index;
info.seedList = config.baseSeed + 100000 * (1:config.numReplicates);
text = sprintf(['%s|%s|%s|%s|T%d|K%d|d%d|M%d|seed%s|ab%.17g,%.17g|sc%.17g|l%.17g|' ...
    'mc
    'context
    'pairing
    config.protocolVersion, config.implementationVersion, config.methodImplementationVersion, ...
    config.name, config.T, config.K, ...
    config.d, config.M, mat2str(info.seedList), config.alpha, config.beta, ...
    config.switchCost, config.lambda, config.simulates, config.recordEvery, ...
    config.oracle, config.feedback, config.regretMetric, strjoin(config.methods, ','), ...
    config.psma.gibbsSweeps, config.gcl2c.gibbsSweeps, config.gcl2c.latentDim, ...
    config.gcl2c.priorPrecision, config.glmucb.delta, config.contextVariant, config.actionSelectionDirection, ...
    config.tieBreakRule, config.channelInterpretation, config.oracleDefinition, ...
    config.regretDefinition, config.integrationNoiseReusePolicy, ...
    config.feedbackPairingPolicy, config.globalIdIndexingVersion);
info.fingerprint = simple_fingerprint(text);
info.runKey = sprintf('T%d_K%d_d%d_M%d_n%d_sc%s_%s', config.T, config.K, config.d, ...
    config.M, config.numReplicates, format_value(config.switchCost), info.fingerprint);
if info.shard.count > 1
    shardTag = sprintf('_shard%dof%d', info.shard.index, info.shard.count);
else
    shardTag = '';
end
info.conditionDirectory = fullfile(config.outputDirectory, 'campaigns', config.campaignId, ...
    ['condition_', info.runKey, shardTag]);
info.checkpointPath = fullfile(info.conditionDirectory, 'comparison_checkpoint.mat');
if ~exist(info.checkpointPath, 'file')
    legacyPath = fullfile(info.conditionDirectory, 'allm_checkpoint.mat');
    if exist(legacyPath, 'file')
        info.checkpointPath = legacyPath;
    end
end
info.tempPath = fullfile(info.conditionDirectory, 'comparison_checkpoint.tmp.mat');
info.completePath = fullfile(info.conditionDirectory, 'comparison_complete.mat');
info.completeTempPath = fullfile(info.conditionDirectory, 'comparison_complete.tmp.mat');
info.shardIndices = find(mod((1:config.numReplicates) - 1, info.shard.count) == ...
    (info.shard.index - 1));
end

function fingerprint = simple_fingerprint(text)
values = double(text);
modulus = 4294967296;
value = 0;
for i = 1:numel(values)
    value = mod(value * 257 + values(i), modulus);
end
fingerprint = lower(dec2hex(uint32(value), 8));
end

function text = format_value(value)
text = strrep(sprintf('%.6g', value), '.', 'p');
text = strrep(text, '-', 'm');
end