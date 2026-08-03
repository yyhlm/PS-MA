classdef TSICFAlg
    properties
        mu=0;
        covariance=0;
        mu0=0;
        Lambda=0;
        Theta=0;
    end

    methods
        function obj=TSICFAlg(d,Theta)
            obj.mu=zeros(d,1);
            obj.covariance=eye(d);
            obj.mu0=obj.mu;
            obj.Lambda=inv(obj.covariance);
            obj.Theta=Theta;
        end

        function x_t=sample(obj)
            x_t=mvnrnd(obj.mu,obj.covariance)';
        end

        function obj=update(obj,reward,tasktype,r_t)
            obj.mu0=obj.mu;
            obj.Lambda=inv(obj.covariance);
            obj.covariance=inv(obj.Lambda+(r_t-obj.Theta(:,tasktype))*(r_t-obj.Theta(:,tasktype))');
            obj.mu=obj.covariance*(obj.Lambda*obj.mu0+(r_t-obj.Theta(:,tasktype))*reward);
        end
    end
end