function run_all_tcp_full()
addpath(genpath(fileparts(mfilename('fullpath'))));
pool = parpool('local', 4);
fprintf('pool workers=%d\n', pool.NumWorkers);
registry = tcp_scenario_registry(tcp_four_method_config());
nKeep = 40;
for s = 1:numel(registry.comparisons)
    entry = registry.comparisons(s);
    config = entry.config;
    info = tcp_checkpoint_info(config);
    if ~exist(info.conditionDirectory, 'dir'), mkdir(info.conditionDirectory); end
    if exist(info.tempPath, 'file'), delete(info.tempPath); end
    checkpoint = init_checkpoint(config, info);
    if exist(info.checkpointPath, 'file')
        loaded = load(info.checkpointPath, '-mat');
        chk = loaded.checkpoint;
        if isfield(chk, 'gclRerunScope') && strcmp(chk.gclRerunScope, 'full')
            checkpoint = chk;
        end
    end
    pending = setdiff(1:nKeep, find(checkpoint.completedMask));
    if isempty(pending)
        fprintf('%s: all %d seeds done\n', entry.id, nKeep);
        continue;
    end
    nRun = numel(pending);
    results = cell(1, nRun);
    parfor kk = 1:nRun
        r = pending(kk);
        cfg = config;
        rep = run_tcp_replicate(cfg, r);
        results{kk} = struct('r', r, 'rep', rep);
        fprintf('%s seed %d/%d\n', entry.id, r, nKeep);
    end
    for kk = 1:nRun
        item = results{kk};
        checkpoint.results{item.r} = item.rep;
        checkpoint.completedMask(item.r) = true;
        checkpoint.lastUpdated = char(datetime('now', 'Format', "yyyy-MM-dd'T'HH:mm:ss"));
    end
    save(info.tempPath, 'checkpoint', '-v7.3');
    tcp_same_directory_replace(info.tempPath, info.checkpointPath);
    fprintf('%s: %d seeds done\n', entry.id, nRun);
end
end
function chk = init_checkpoint(config, info)
chk.schemaVersion = 'tcp_checkpoint_v1';
chk.campaignId = config.campaignId;
chk.protocolVersion = config.protocolVersion;
chk.implementationVersion = config.implementationVersion;
chk.configFingerprint = info.fingerprint;
chk.seedList = info.seedList;
chk.completedMask = false(1, config.numReplicates);
chk.results = cell(1, config.numReplicates);
chk.lastUpdated = '';
chk.gclRerunScope = 'full';
end