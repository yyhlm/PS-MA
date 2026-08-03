function observation = observe_allm_arm(env, config, t, arm, previousArm, feedbackStream)

m = env.public.taskType(t);
if nargin < 6 || isempty(feedbackStream)
    noiseCp = randn;
    noiseCm = randn;
else
    noiseCp = randn(feedbackStream);
    noiseCm = randn(feedbackStream);
end
rewardCp = config.alpha * logsig(env.oracle.u_inpro_cp(arm, m) + noiseCp);
rewardCm = config.beta * logsig(env.oracle.u_inpro_cm(arm, m) + noiseCm);
observation.rewardCompute = rewardCp;
observation.rewardComm = rewardCm;
observation.reward = rewardCp + rewardCm;
observation.processingCost = rewardCp + rewardCm;
observation.switchCost = config.switchCost * double(previousArm ~= 0 && previousArm ~= arm);
observation.totalCost = rewardCp + rewardCm + observation.switchCost;
observation.arm = arm;
observation.logitCompute = log(rewardCp) - log(config.alpha - rewardCp);
observation.logitComm = log(rewardCm) - log(config.beta - rewardCm);
end