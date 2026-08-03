function draw_all12_black()
edgeRoot = fileparts(mfilename('fullpath'));
tcpRoot = fullfile(fileparts(edgeRoot), 'TCP');
edgeMethods = {'psma','hlinucb','tsicf','gcl2c','glmucb'};
edgeLabels = {'PS-MA','hLinUCB','TS-ICF','GCL-PSMC','GLM-UCB'};
tcpMethods = {'psma','hlinucb','tsicf','gcl','glmucb'};
tcpLabels = edgeLabels;
styles = {'-*','-o','-x','-^','-s'};

addpath(genpath(edgeRoot));
edgeRegistry = allm_scenario_registry(allm_config());
for i = 1:numel(edgeRegistry.comparisons)
    entry = edgeRegistry.comparisons(i);
    if strcmp(entry.id,'edge_default')
        config = entry.config; config.numReplicates = 1000;
        info = allm_checkpoint_info(config);
        formal = load(info.checkpointPath,'checkpoint').checkpoint;
        sources = cell(1,20);
        for s = 1:20, sources{s} = formal.results{s}; end
    else
        config = entry.config;
        info = allm_checkpoint_info(config);
        formal = load(info.checkpointPath,'checkpoint').checkpoint;
        sources = cell(1,20);
        for s = 1:20, sources{s} = formal.results{s}; end
    end
    fig = figure('Visible','off','Color','w','Position',[100 100 760 520]); hold on;
    for m = 1:numel(edgeMethods)
        Y = zeros(20,101);
        for s = 1:20, Y(s,:) = sources{s}.(edgeMethods{m}).Regret; end
        plot(0:20:2000,mean(Y,1),styles{m},'Color',[0 0 0], ...
            'LineWidth',1.2,'MarkerSize',5,'DisplayName',edgeLabels{m});
    end
    format_figure(fig,'Edge Computing',fullfile(edgeRoot,'results', ...
        ['edge_',entry.id,'_mean_regret_S20_black']));
    close(fig);
end

addpath(genpath(tcpRoot));
tcpRegistry = tcp_scenario_registry(tcp_four_method_config());
for i = 1:numel(tcpRegistry.comparisons)
    entry = tcpRegistry.comparisons(i);
    config = entry.config; config.numReplicates = 1000;
    info = tcp_checkpoint_info(config);
    formal = load(info.checkpointPath,'checkpoint').checkpoint;
    fig = figure('Visible','off','Color','w','Position',[100 100 760 520]); hold on;
    for m = 1:numel(tcpMethods)
        Y = zeros(20,101);
        for s = 1:20, Y(s,:) = formal.results{s}.(tcpMethods{m}).Regret; end
        plot(0:20:2000,mean(Y,1),styles{m},'Color',[0 0 0], ...
            'LineWidth',1.2,'MarkerSize',5,'DisplayName',tcpLabels{m});
    end
    format_figure(fig,'TCP',fullfile(tcpRoot,'results', ...
        ['tcp_',entry.id,'_mean_regret_S20_black']));
    close(fig);
end
fprintf('Generated 12 black S20 regret plots.\n');
end

function format_figure(fig,titleText,stem)
xlim([0 2000]); xlabel('T','FontName','Times New Roman','FontSize',12);
ylabel('Average Regret','FontName','Times New Roman','FontSize',12);
title(titleText,'FontName','Times New Roman','FontSize',12);
legend('Location','northwest','FontName','Times New Roman','FontSize',10);
set(gca,'FontName','Times New Roman','FontSize',11,'Box','on','LineWidth',0.8);
grid off;
exportgraphics(fig,[stem,'.png'],'Resolution',200);
exportgraphics(fig,[stem,'.pdf'],'ContentType','vector');
end