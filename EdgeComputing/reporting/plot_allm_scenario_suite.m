function paths = plot_allm_scenario_suite(suite, outputDirectory)

if ~exist(outputDirectory, 'dir')
    mkdir(outputDirectory);
end
switch suite.selection
    case 'comparisons'
        paths = plot_comparison_conditions(suite, outputDirectory);
    case 'psma_sweeps'
        paths = plot_psma_sweeps(suite, outputDirectory);
    otherwise
        error('allm:UnknownScenarioSuite', 'Unknown suite selection: %s', suite.selection);
end
end

function paths = plot_comparison_conditions(suite, outputDirectory)
conditions = suite.conditions;
paths = struct();
for i = 1:numel(conditions)
    campaign = conditions(i).campaign;
    stem = sprintf('%s_%s_regret', campaign.runKey, conditions(i).id);
    paths.(conditions(i).id) = plot_campaign_regret(campaign, stem, outputDirectory);
end
end

function paths = plot_psma_sweeps(suite, outputDirectory)
paths = struct();
dimensions = unique([suite.conditions.dimension]);
for d = dimensions
    members = suite.conditions([suite.conditions.dimension] == d);
    figureHandle = figure('Visible', 'off');
    hold on;
    for i = 1:numel(members)
        campaign = members(i).campaign;
        source = campaign.summary.psma.regretCurve;
        steps = campaign.summary.recordSteps;
        plot(steps, source.mean, 'LineWidth', 1.5, ...
            'DisplayName', sprintf('PS-MA (N=%d)', members(i).gibbsSweeps));
    end
    xlabel('Round'); ylabel('Cumulative greedy cost regret');
    legend('Location', 'best'); grid on;
    stem = sprintf('allm_edge_exp1_d%d_psma_sweeps', d);
    paths.(sprintf('d%d', d)).png = fullfile(outputDirectory, [stem, '.png']);
    paths.(sprintf('d%d', d)).pdf = fullfile(outputDirectory, [stem, '.pdf']);
    exportgraphics(figureHandle, paths.(sprintf('d%d', d)).png, 'Resolution', 200);
    exportgraphics(figureHandle, paths.(sprintf('d%d', d)).pdf, 'ContentType', 'vector');
    close(figureHandle);
end
end

function paths = plot_campaign_regret(campaign, stem, outputDirectory)
figureHandle = figure('Visible', 'off');
hold on;
steps = campaign.summary.recordSteps;
methods = campaign.config.methods;
for i = 1:numel(methods)
    key = methods{i}; source = campaign.summary.(key).regretCurve;
    fill([steps, fliplr(steps)], [source.ci95(1, :), fliplr(source.ci95(2, :))], ...
        [0.7, 0.7, 0.7], 'FaceAlpha', 0.12, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    plot(steps, source.mean, 'LineWidth', 1.5, 'DisplayName', allm_method_label(key));
end
xlabel('Round'); ylabel('Cumulative greedy cost regret');
legend('Location', 'best', 'Interpreter', 'none'); grid on;
paths.png = fullfile(outputDirectory, [stem, '.png']);
paths.pdf = fullfile(outputDirectory, [stem, '.pdf']);
exportgraphics(figureHandle, paths.png, 'Resolution', 200);
exportgraphics(figureHandle, paths.pdf, 'ContentType', 'vector');
close(figureHandle);
end