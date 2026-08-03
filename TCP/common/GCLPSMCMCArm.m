classdef GCLPSMCMCArm
    properties
        id=0
        X=0;
        mu=0;
        covariance=0;
        mu0=0;
        Lambda=0;
        allreward=0;
        count=0;
        arm_index=0;
    end

    methods
        function obj=GCLPSMCMCArm(id,X,K,L)
            obj.id=id;
            obj.X=X;
            obj.mu=zeros(L,1);
            obj.covariance=eye(L);
            obj.mu0=obj.mu;
            obj.Lambda=inv(obj.covariance);
            obj.arm_index=zeros(1,K);
        end

        function x_t=sample(obj)
            x_t=mvnrnd(obj.mu,obj.covariance)';
        end

        function obj=update(obj,reward,theta_t,arm,K,d)
            if reward==0
                obj.covariance=inv(obj.Lambda+obj.count*(theta_t(d+1:end)*theta_t(d+1:end)'));
                temp=0;
                for i=1:K
                    temp=temp+obj.arm_index(i)*obj.X(:,i);
                end
                temp=theta_t(d+1:end)*(obj.allreward-theta_t(1:d)'*temp)+obj.Lambda*obj.mu0;
                obj.mu=obj.covariance*temp;
            else
                obj.count=obj.count+1;
                obj.allreward=obj.allreward+reward;
                obj.arm_index(arm)=obj.arm_index(arm)+1;
                obj.covariance=inv(obj.Lambda+obj.count*(theta_t(d+1:end)*theta_t(d+1:end)'));
                temp=0;
                for i=1:K
                    temp=temp+obj.arm_index(i)*obj.X(:,i);
                end
                temp=theta_t(d+1:end)*(obj.allreward-theta_t(1:d)'*temp)+obj.Lambda*obj.mu0;
                obj.mu=obj.covariance*temp;
            end
        end
    end
end