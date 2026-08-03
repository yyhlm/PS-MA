function paths = plot_tcp_comparison(comparison)

outputDirectory = comparison.config.outputDirectory;
if ~exist(outputDirectory, 'dir')
    mkdir(outputDirectory);
end
paths.regret = plot_metric(comparison, 'regretCurve', 'Average cost regret', ...
    [comparison.runKey, '_regret'], outputDirectory);
paths.delay = plot_metric(comparison, 'delayCurve', 'Average observed delay', ...
    [comparison.runKey, '_delay'], outputDirectory);
end

function paths = plot_metric(comparison, metric, yLabel, stem, outputDirectory)
figureHandle = figure('Visible', 'off');
hold on;
steps = comparison.summary.recordSteps;
methods = comparison.config.methods;
for i = 1:numel(methods)
    source = comparison.summary.(methods{i}).(metric);
    lower = source.ci95(1, :);
    upper = source.ci95(2, :);
    fill([steps, fliplr(steps)], [lower, fliplr(upper)], ...
        [0.7, 0.7, 0.7], 'FaceAlpha', 0.12, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
    plot(steps, source.mean, 'LineWidth', 1.5, 'DisplayName', ...
        tcp_method_label(methods{i}));
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