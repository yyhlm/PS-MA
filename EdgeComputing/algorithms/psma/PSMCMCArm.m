classdef PSMCMCArm
    properties
        id=0;
        mu=0;
        covariance=0;
        mu0=0;
        Lambda=0;
        Theta=0;
        count=0;
        allreward=0;
        alltheta=0;
    end

    methods
        function obj=PSMCMCArm(id,d,Theta)
            obj.id=id;
            obj.mu=zeros(d,1);
            obj.covariance=eye(d);
            obj.mu0=obj.mu;
            obj.Lambda=inv(obj.covariance);
            obj.Theta=Theta;
            obj.count=0;
            obj.allreward=0;
            obj.alltheta=zeros(d,1);
        end

        function r_t=sample(obj)
            r_t=mvnrnd(obj.mu,obj.covariance)';
        end

        function obj=update(obj,reward,tasktype,x_t)
            if reward==0
                obj.covariance=inv(obj.Lambda+obj.count*(x_t*x_t'));
                obj.mu=obj.covariance*(obj.Lambda*obj.mu0+x_t*obj.allreward+x_t*x_t'*obj.alltheta);
            else
                obj.count=obj.count+1;
                obj.allreward=obj.allreward+reward;
                obj.alltheta=obj.alltheta+obj.Theta(:,tasktype);
                obj.covariance=inv(obj.Lambda+obj.count*(x_t*x_t'));
                obj.mu=obj.covariance*(obj.Lambda*obj.mu0+x_t*obj.allreward+x_t*x_t'*obj.alltheta);
            end
        end
    end
end