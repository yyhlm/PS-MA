function paths = plot_allm_campaign(campaign)

outputDirectory = campaign.config.outputDirectory;
if ~exist(outputDirectory, 'dir')
    mkdir(outputDirectory);
end
paths.regret = plot_metric(campaign, 'regretCurve', 'Cumulative greedy cost regret', ...
    [campaign.runKey, '_regret'], outputDirectory);
paths.delay = plot_metric(campaign, 'delayCurve', 'Cumulative observed delay', ...
    [campaign.runKey, '_delay'], outputDirectory);
end

function paths = plot_metric(campaign, metric, yLabel, stem, outputDirectory)
figureHandle = figure('Visible', 'off');
hold on;
steps = campaign.summary.recordSteps;
methods = campaign.config.methods;
for i = 1:numel(methods)
    source = campaign.summary.(methods{i}).(metric);
    lower = source.ci95(1, :);
    upper = source.ci95(2, :);
    fill([steps, fliplr(steps)], [lower, fliplr(upper)], ...
        [0.7, 0.7, 0.7], 'FaceAlpha', 0.12, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
    plot(steps, source.mean, 'LineWidth', 1.5, 'DisplayName', ...
        allm_method_label(methods{i}));
end
xlabel('Round');
ylabel(yLabel);
legend('Location', 'best', 'Interpreter', 'none');
grid on;
paths.png = fullfile(outputDirectory, [stem, '.png']);
paths.pdf = fullfile(outputDirectory, [stem, '.pdf']);
exportgraphics(figureHandle, paths.png, 'Resolution', 200);
exportgraphics(figureHandle, paths.pdf, 'ContentType', 'vector');
close(figureHandle);
end