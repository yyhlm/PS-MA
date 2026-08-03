function campaign = run_allm_shard(config, shardIndex, shardCount)

assert(nargin == 3, 'allm:InvalidArgs', 'Usage: run_allm_shard(config, shardIndex, shardCount)');
config.shard.count = shardCount;
config.shard.index = shardIndex;
config.resume = true;
campaign = run_allm_campaign(config);
end