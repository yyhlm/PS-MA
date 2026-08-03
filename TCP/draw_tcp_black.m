function draw_tcp_black()
root = fileparts(mfilename('fullpath'));
addpath(genpath(root));
registry = tcp_scenario_registry(tcp_four_method_config());
methods = {'psma','hlinucb','tsicf','gcl','glmucb'};
labels = {'PS-MA','hLinUCB','TS-ICF','GCL-PSMC','GLM-UCB'};
markers = {'o','x','d','s','^'};
linestyles = {'-','--','--','-','-.'};
T = 2000;
recordEvery = T/100;
Time = 0:recordEvery:T;
idx25 = 1:4:numel(Time);
outDir = fullfile(root, 'results');
if ~exist(outDir, 'dir'), mkdir(outDir); end
for i = 1:numel(registry.comparisons)
    entry = registry.comparisons(i);
    config = entry.config;
    info = tcp_checkpoint_info(config);
        if ~exist(info.checkpointPath, 'file')
        campaignsDir = fullfile(root, 'results', 'campaigns');
        found = false;
        if exist(campaignsDir, 'dir')
            campDirs = dir(fullfile(campaignsDir, config.campaignId, 'condition_*'));
            for d = 1:numel(campDirs)
                cp = fullfile(campDirs(d).folder, campDirs(d).name, 'comparison_checkpoint.mat');
                if exist(cp, 'file')
                    info.checkpointPath = cp;
                    found = true;
                    break;
                end
            end
        end
        if ~found
            warning('tcp:NoCheckpoint', 'Missing checkpoint for %s', entry.id);
            continue;
        end
    end
    loaded = load(info.checkpointPath, 'checkpoint');
    checkpoint = loaded.checkpoint;
    if isfield(checkpoint, 'completedMask')
        completedIdx = find(checkpoint.completedMask);
        nSeeds = numel(completedIdx);
    else
        nSeeds = numel(checkpoint.results);
    end
    if nSeeds == 0
        warning('tcp:NoCompletedSeeds', 'No completed seeds for %s.', entry.id);
        continue;
    end
        figR = figure('Visible','off','Color','w','Units','pixels', ...
        'Position',[100 100 560 420], 'PaperUnits','points', ...
        'PaperPosition',[0 0 420 315], 'PaperSize',[420 315], ...
        'PaperPositionMode','manual');
    hold on;
    regretMax = 0;
    for m = 1:numel(methods)
        curves = zeros(nSeeds, numel(Time));
        for s = 1:nSeeds
            curves(s,:) = checkpoint.results{s}.(methods{m}).Regret;
        end
        meanCurve = mean(curves, 1);
        plot(Time(idx25), meanCurve(idx25), ...
            [linestyles{m} markers{m} 'k'], 'LineWidth', 1.5, 'MarkerSize', 6);
        regretMax = max(regretMax, max(meanCurve(idx25)));
    end
    axis([0 T*1.05 0 regretMax*1.3]);
    legend(labels, 'Location', 'northwest');
    xlabel('T');
    ylabel('Average Regret');
        set(gca, 'FontSize', 16, 'FontWeight', 'bold', 'Box', 'on', 'LineWidth', 0.8);
    grid off;
    stemR = fullfile(outDir, [entry.id, '_mean_regret_S', num2str(nSeeds), '_black']);
    exportgraphics(figR, [stemR, '.png'], 'Resolution', 200);
    exportgraphics(figR, [stemR, '.pdf'], 'ContentType', 'vector');
    print(figR, [stemR, '.eps'], '-depsc2', '-r200', '-loose');
    close(figR);
    fprintf('%s\n', stemR);
end
end