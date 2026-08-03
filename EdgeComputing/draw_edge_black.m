function draw_edge_black()
root = fileparts(mfilename('fullpath'));
addpath(genpath(root));
registry = allm_scenario_registry();
methods = {'psma','hlinucb','tsicf','gcl2c','glmucb'};
labels = {'PS-MA','hLinUCB','TS-ICF','GCL-PSMC','GLM-UCB'};
markers = {'o','x','d','s','^'};
linestyles = {'-','--','--','-','-.'};
T = 2000;
recordEvery = T/100;
Time = 0:recordEvery:T;
idx25 = 5:4:numel(Time);
nKeep = 100;
outDir = fullfile(root, 'results');
if ~exist(outDir, 'dir'), mkdir(outDir); end
for i = 1:numel(registry.comparisons)
    entry = registry.comparisons(i);
    config = entry.config;
    info = allm_checkpoint_info(config);
    if ~exist(info.checkpointPath, 'file')
        warning('allm:NoCheckpoint', 'Missing checkpoint for %s', entry.id);
        continue;
    end
    loaded = load(info.checkpointPath, 'checkpoint');
    checkpoint = loaded.checkpoint;
    completedIdx = find(checkpoint.completedMask);
    if numel(completedIdx) < nKeep
        warning('allm:IncompletePlotData', 'Only %d seeds for %s, need %d', ...
            numel(completedIdx), entry.id, nKeep);
        continue;
    end
    keepIdx = completedIdx(1:nKeep);
        figR = figure('Visible','off','Color','w','Position',[100 100 760 520]);
    hold on;
    regretMax = 0;
    for m = 1:numel(methods)
        curves = zeros(nKeep, numel(Time));
        for s = 1:nKeep
            rep = checkpoint.results{keepIdx(s)};
            curves(s,:) = rep.(methods{m}).Regret;
        end
        meanCurve = mean(curves, 1);
        plot(Time(idx25), meanCurve(idx25), ...
            [linestyles{m} markers{m} 'k'], 'LineWidth', 1.5, 'MarkerSize', 6);
        regretMax = max(regretMax, max(meanCurve(idx25)));
    end
    axis([0 T*1.05 0 regretMax*1.3]);
    legend(labels, 'Location', 'northwest');
    xlabel('T', 'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('Average Regret', 'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold');
    title(entry.id, 'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold');
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold', ...
        'Box', 'on', 'LineWidth', 0.8);
    grid off;
    stemR = fullfile(outDir, [entry.id, '_mean_regret_S100_black']);
    exportgraphics(figR, [stemR, '.png'], 'Resolution', 200);
    exportgraphics(figR, [stemR, '.pdf'], 'ContentType', 'vector');
    print(figR, [stemR, '.eps'], '-depsc2', '-r200');
    close(figR);
    fprintf('%s\n', stemR);
end
end