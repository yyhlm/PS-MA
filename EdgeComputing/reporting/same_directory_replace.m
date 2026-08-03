function same_directory_replace(tempPath, targetPath)

[ok, message] = movefile(tempPath, targetPath, 'f');
assert(ok, 'allm:CheckpointWrite', 'Unable to publish %s: %s', targetPath, message);
end