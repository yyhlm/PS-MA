function observation = observe_selected_arm_tcp(env, config, feedbackStream, t, pathId, previousArm)

if ~ismember(pathId, env.public.candidateIds{t})
    error('tcpcmp:InvalidAction', 'Selected path is unavailable.');
end
L = config.numLinksPerPath;
feedbackNoise = config.feedbackNoiseStd * randn(feedbackStream, 1, L);
linkLogits = reshape(env.oracle.baseLogitByPath(pathId, :, t), 1, L) + feedbackNoise;
linkNormalizedValue = sigmoid_stable(linkLogits);
linkWeightedValue = config.Weight .* linkNormalizedValue;

observation.pathId = pathId;
observation.entityIds = env.public.P{pathId};
observation.linkNormalizedValue = linkNormalizedValue;
observation.linkWeightedValue = linkWeightedValue;
observation.linkLogitFeedback = logit_clipped(linkNormalizedValue, config.feedbackEpsilon);
observation.processingCost = sum(linkWeightedValue);
observation.normalizedCost = observation.processingCost / config.totalPathWeight;
observation.reward = config.totalPathWeight - observation.processingCost;
observation.switchCost = 0;
observation.totalCost = observation.processingCost;
assert(previousArm == 0 || previousArm >= 1, 'tcpcmp:InvalidPreviousArm', ...
    'Previous path ID is invalid.');
end