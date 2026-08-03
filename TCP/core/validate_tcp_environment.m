function validate_tcp_environment(env, config)
assert(isequal(size(env.oracle.expectedProcessingCost),[config.K,config.T]),'tcpcmp:ExpectedCost','Expected cost shape mismatch.');
assert(~isfield(env.oracle,'feedbackNoise'),'tcpcmp:Noise','Environment must not freeze a feedbackNoise tensor; realized feedback is per-method per-round.');
assert(all(env.oracle.expectedProcessingCost(:)>=0 & env.oracle.expectedProcessingCost(:)<=config.totalPathWeight),'tcpcmp:CostRange','Expected cost outside [0,totalWeight].');
assert(isequal(size(env.public.knownContext),[config.d,config.T]),'tcpcmp:Context','Known context shape mismatch.');
for t=1:config.T
    assert(isequal(env.public.candidateIds{t}(:),(1:config.K).'),'tcpcmp:Candidates','TCP candidate set must contain all paths.');
end
for path=1:config.K
    assert(numel(env.public.P{path})==config.numLinksPerPath,'tcpcmp:Topology','Every path must have six positions.');
end
end