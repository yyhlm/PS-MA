function summary = summarize_tcp_comparison(results, config)

n = numel(results);
recordSteps = 0:config.recordEvery:config.T;
summary.numReplicates = n;
summary.recordSteps = recordSteps;
for m = 1:numel(config.methods)
    key = config.methods{m};
    finalRegret = zeros(n, 1); finalDelay = zeros(n, 1);
    runtime = zeros(n, 1); switchCount = zeros(n, 1);
    regret = zeros(n, numel(recordSteps)); delay = zeros(n, numel(recordSteps));
    for r = 1:n
        result = results{r}.(key);
        metrics = results{r}.([key, 'Metrics']);
        finalRegret(r) = metrics.offlineDynamicCostRegret(end);
        finalDelay(r) = result.finalDelay;
        runtime(r) = result.runtimeSeconds;
        switchCount(r) = sum(diff(result.selectedArm) ~= 0);
        regret(r, :) = [0, metrics.offlineDynamicCostRegret];
        cumulativeDelay = cumsum(result.processingCost);
        delay(r, :) = [0, cumulativeDelay(config.recordEvery:config.recordEvery:config.T)];
    end
    summary.(key).finalRegret = describe(finalRegret);
    summary.(key).finalDelay = describe(finalDelay);
    summary.(key).runtimeSeconds = describe(runtime);
    summary.(key).switchCount = describe(switchCount);
    summary.(key).regretCurve = describe_rows(regret);
    summary.(key).delayCurve = describe_rows(delay);
end
if any(strcmp(config.methods, 'psma'))
    comparisons = struct();
    psma = cellfun(@(r) r.psmaMetrics.offlineDynamicCostRegret(end), results)';
    for m = 1:numel(config.methods)
        key = config.methods{m};
        if strcmp(key, 'psma'), continue; end
        delta = cellfun(@(r) r.([key, 'Metrics']).offlineDynamicCostRegret(end), results)' - psma;
        comparisons.(key).label = [key, ' minus psma (paired environments)'];
        comparisons.(key).difference = delta;
        comparisons.(key).statistics = describe(delta);
        comparisons.(key).psmaWins = sum(delta > 1e-12);
        comparisons.(key).ties = sum(abs(delta) <= 1e-12);
        comparisons.(key).comparatorWins = sum(delta < -1e-12);
    end
    summary.pairedEnvironmentComparisons = comparisons;
end
end

function statistics = describe(values)
n = numel(values);
statistics.mean = mean(values); statistics.std = std(values);
statistics.se = statistics.std / sqrt(n);
statistics.ci95 = statistics.mean + [-1, 1] * t_critical_95(n) * statistics.se;
end

function statistics = describe_rows(values)
statistics.mean = mean(values, 1); statistics.std = std(values, 0, 1);
statistics.se = statistics.std / sqrt(size(values, 1));
statistics.ci95 = [statistics.mean - t_critical_95(size(values, 1)) * statistics.se; ...
    statistics.mean + t_critical_95(size(values, 1)) * statistics.se];
end

function critical = t_critical_95(n)
values = [12.706, 4.303, 3.182, 2.776, 2.571, 2.447, 2.365, 2.306, ...
    2.262, 2.228, 2.201, 2.179, 2.160, 2.145, 2.131, 2.120, 2.110, ...
    2.101, 2.093, 2.086, 2.080, 2.074, 2.069, 2.064, 2.060, 2.056, ...
    2.052, 2.048, 2.045];
if n <= 1
    critical = 0;
elseif n - 1 <= numel(values)
    critical = values(n - 1);
else
    critical = 1.96;
end
end