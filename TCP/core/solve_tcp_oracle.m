function oracle = solve_tcp_oracle(env, config)
[minimumCost, actions] = min(env.oracle.expectedProcessingCost, [], 1);
oracle.actions=actions; oracle.prefixExpectedTotalCost=cumsum(minimumCost);
oracle.totalExpectedTotalCost=oracle.prefixExpectedTotalCost(end);
oracle.totalExpectedNetReward=config.totalPathWeight*config.T-oracle.totalExpectedTotalCost;
oracle.prefixNetReward=config.totalPathWeight*(1:config.T)-oracle.prefixExpectedTotalCost;
oracle.switchCount=sum(diff(actions)~=0); oracle.switchingCost=0;
end