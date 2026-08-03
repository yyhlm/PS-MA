classdef GCLPSMCMCAlg
    properties
        mu=0;
        covariance=0;
        mu0=0;
        Lambda=0;
        arm_index=0;
        reward_index=0;
    end

    methods
        function obj=GCLPSMCMCAlg(K,d)
            obj.mu=zeros(d,1);
            obj.covariance=eye(d);
            obj.mu0=obj.mu;
            obj.Lambda=inv(obj.covariance);
            obj.arm_index=zeros(1,K);
            obj.reward_index=zeros(1,K);
        end

        function theta_t=sample(obj)
            theta_t=mvnrnd(obj.mu,obj.covariance)';
        end

        function obj=update(obj,reward,arm,X_t,K)
            if reward==0
                temp=obj.Lambda;
                for i=1:K
                    temp=temp+obj.arm_index(i)*(X_t(:,i)*X_t(:,i)');
                end
                obj.covariance=inv(temp);
                temp=obj.Lambda*obj.mu0;
                for i=1:K
                    temp=temp+X_t(:,i)*obj.reward_index(i);
                end
                obj.mu=obj.covariance*temp;
            else
                obj.arm_index(arm)=obj.arm_index(arm)+1;
                obj.reward_index(arm)=obj.reward_index(arm)+reward;
                temp=obj.Lambda;
                for i=1:K
                    temp=temp+obj.arm_index(i)*(X_t(:,i)*X_t(:,i)');
                end
                obj.covariance=inv(temp);
                temp=obj.Lambda*obj.mu0;
                for i=1:K
                    temp=temp+X_t(:,i)*obj.reward_index(i);
                end
                obj.mu=obj.covariance*temp;
            end
        end
    end
end