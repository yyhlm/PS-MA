function publish_tcp_v2_figures()
root = fileparts(mfilename('fullpath'));
addpath(genpath(root));
registry = tcp_scenario_registry(tcp_four_method_config());
for i = 1:numel(registry.comparisons)
    entry = registry.comparisons(i);
    config = entry.config;
    info = tcp_checkpoint_info(config);
    loaded = load(info.checkpointPath, 'checkpoint');
    checkpoint = loaded.checkpoint;
    completedIdx = find(checkpoint.completedMask);
    results = checkpoint.results(completedIdx);
    assert(numel(results) >= 20, 'tcpcmp:Incomplete', ...
        'Need >=20 seeds for
    results = results(1:20);
    comparison.schemaVersion = 'tcp_comparison_v1';
    comparison.campaignId = config.campaignId;
    comparison.configFingerprint = info.fingerprint;
    comparison.runKey = info.runKey;
    comparison.config = config;
    comparison.results = results;
    comparison.summary = summarize_tcp_comparison(results, config);
    comparison.seedList = info.seedList(1:20);
    comparison.metricSchemaVersion = config.metricSchemaVersion;
    comparison.canonicalMetric = config.canonicalMetric;
    comparison.completedAt = char(datetime('now', 'Format', "yyyy-MM-dd'T'HH:mm:ss"));
    config.publishResults = true; config.makeFigures = true;
    config.outputDirectory = fullfile(root, 'results', ['v2_', entry.id]);
    if ~exist(config.outputDirectory, 'dir'), mkdir(config.outputDirectory); end
    comparison.config = config;
    tcp_save_comparison_result(comparison);
    export_tcp_comparison_table(comparison);
    plot_tcp_comparison(comparison);
    fprintf('tcp %s published to %s\n', entry.id, config.outputDirectory);
end
end