classdef TCPHLinUCBArm
properties
    id
    C
    C_inv
    d
    r_t
    Theta
end
methods
    function obj = TCPHLinUCBArm(id, d, Theta)
        obj.id = id; obj.C = eye(d); obj.C_inv = eye(d); obj.d = zeros(d, 1);
        obj.r_t = unifrnd(0, 1, d, 1); obj.Theta = Theta;
    end
    function obj = update(obj, reward, tasktype, x_t)
        obj.C = obj.C + x_t * x_t'; obj.d = obj.d + x_t * reward;
        obj.r_t = obj.C \ obj.d + obj.Theta(:, tasktype); obj.C_inv = inv(obj.C);
    end
end
end