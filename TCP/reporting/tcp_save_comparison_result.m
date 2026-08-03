function tcp_save_comparison_result(comparison)
outputDirectory=comparison.config.outputDirectory; if ~exist(outputDirectory,'dir'), mkdir(outputDirectory); end
filename=sprintf('%s_%s_T%d_K%d_n%d.mat',comparison.config.name,comparison.configFingerprint,comparison.config.T,comparison.config.K,comparison.config.numReplicates);
tempPath=fullfile(outputDirectory,[filename,'.tmp']); finalPath=fullfile(outputDirectory,filename);
save(tempPath,'comparison','-v7.3'); tcp_same_directory_replace(tempPath,finalPath);
end