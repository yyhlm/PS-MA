classdef TSICFArm
    properties
        id=0
        mu=0;
        covariance=0;
        mu0=0;
        Lambda=0;
        Theta=0;
    end

    methods
        function obj=TSICFArm(id,d,Theta)
            obj.id=id;
            obj.mu=zeros(d,1);
            obj.covariance=eye(d);
            obj.mu0=obj.mu;
            obj.Lambda=inv(obj.covariance);
            obj.Theta=Theta;
        end

        function r_t=sample(obj)
            r_t=mvnrnd(obj.mu,obj.covariance)';
        end

        function obj=update(obj,reward,tasktype,x_t)
            obj.mu0=obj.mu;
            obj.Lambda=inv(obj.covariance);
            obj.covariance=inv(obj.Lambda+x_t*x_t');
            obj.mu=obj.covariance*(obj.Lambda*obj.mu0+x_t*(reward+x_t'*obj.Theta(:,tasktype)));
        end
    end
end