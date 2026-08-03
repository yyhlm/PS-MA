classdef hLinUCBArm
    properties
        id=0;
        C=0;
        C_inv=0;
        d=0;
        r_t=0;
        Theta=0;
    end

    methods
        function obj=hLinUCBArm(id,d,Theta)
            obj.id=id;
            obj.C=eye(d);
            obj.C_inv=eye(d);
            obj.d=zeros(d,1);
            obj.r_t=unifrnd(0,1,d,1);
            obj.Theta=Theta;
        end

        function value=calculate(obj,alpha1,alpha2,x_t,A_inv,tasktype)
            value=x_t'*(obj.r_t-obj.Theta(:,tasktype))+alpha1*sqrt((obj.r_t-obj.Theta(:,tasktype))'...
                *A_inv*(obj.r_t-obj.Theta(:,tasktype)))+alpha2*sqrt(x_t'*obj.C_inv*x_t);
        end

        function obj=update(obj,reward,tasktype,x_t)
            obj.C=obj.C+x_t*x_t';
            obj.d=obj.d+x_t*reward;
            obj.r_t=obj.C\obj.d+obj.Theta(:,tasktype);
            obj.C_inv=inv(obj.C);
        end
    end
end