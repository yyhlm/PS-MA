function metrics = evaluate_tcp_metrics(result, env, oracle, config)
T=config.T; recordAt=config.recordEvery:config.recordEvery:T;
expectedCost=zeros(1,T);
requiredFields={'processingCost','totalCost','reward','switchCost','selectedArm', ...
    'decisionSeconds','updateSeconds'};
for field=1:numel(requiredFields)
    name=requiredFields{field};
    assert(isfield(result,name) && isequal(size(result.(name)),[1,T]) && ...
        all(isfinite(result.(name))), 'tcpcmp:MissingPhysicalCost', ...
        'Result lacks a finite 1-by-T
end
assert(max(abs(result.totalCost-(result.processingCost+result.switchCost)))<1e-10, ...
    'tcpcmp:CostInconsistency','totalCost must equal processingCost plus switchCost.');
assert(max(abs(result.reward-(config.totalPathWeight-result.processingCost)))<1e-10, ...
    'tcpcmp:CostInconsistency','reward must be the declared complement of processingCost.');
observedCost=result.processingCost;
for t=1:T
    path=result.selectedArm(t);
    assert(ismember(path,env.public.candidateIds{t}),'tcpcmp:InvalidAction','Selected path unavailable.');
    expectedCost(t)=env.oracle.expectedProcessingCost(path,t);
end
assert(all(result.switchCost==0),'tcpcmp:SwitchAccounting','TCP comparison has no switching cost.');
cumulativeExpectedCost=cumsum(expectedCost); cumulativeObservedCost=cumsum(observedCost);
cumulativeObservedReward=cumsum(result.reward); bestCost=min(env.oracle.expectedProcessingCost,[],1);
pseudoRegret=cumulativeExpectedCost-cumsum(bestCost);
assert(all(pseudoRegret>=-1e-10),'tcpcmp:NegativePseudoRegret','Cost oracle must dominate policy trace.');
metrics.method=result.method; metrics.recordAt=recordAt;
metrics.cumulativeExpectedProcessingCost=cumulativeExpectedCost(recordAt); metrics.cumulativeExpectedTotalCost=metrics.cumulativeExpectedProcessingCost;
metrics.cumulativeObservedProcessingCost=cumulativeObservedCost(recordAt); metrics.cumulativeObservedTotalCost=metrics.cumulativeObservedProcessingCost;
metrics.cumulativeObservedReward=cumulativeObservedReward(recordAt); metrics.oraclePrefixExpectedTotalCost=oracle.prefixExpectedTotalCost(recordAt);
metrics.offlineDynamicCostRegret=pseudoRegret(recordAt); metrics.expectedProcessingPseudoRegret=metrics.offlineDynamicCostRegret;
metrics.switchCount=sum(diff(result.selectedArm)~=0); metrics.totalDecisionSeconds=sum(result.decisionSeconds); metrics.totalUpdateSeconds=sum(result.updateSeconds);
metrics.oracleExpectedTotalCost=oracle.totalExpectedTotalCost; metrics.oracleSwitchCount=oracle.switchCount;
end