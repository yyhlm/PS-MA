function tcp_same_directory_replace(sourcePath,destinationPath)
if exist(destinationPath,'file'), delete(destinationPath); end
movefile(sourcePath,destinationPath,'f');
end