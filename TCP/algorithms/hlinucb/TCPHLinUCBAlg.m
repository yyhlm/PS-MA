classdef TCPHLinUCBAlg
properties
    id
    A
    A_inv
    b
    x_t
    Theta
end
methods
    function obj = TCPHLinUCBAlg(id, d, Theta)
        obj.id = id; obj.A = eye(d); obj.A_inv = eye(d); obj.b = zeros(d, 1);
        obj.x_t = unifrnd(0, 1, d, 1); obj.Theta = Theta;
    end
    function obj = update(obj, reward, tasktype, r_t)
        feature = r_t - obj.Theta(:, tasktype);
        obj.A = obj.A + feature * feature'; obj.b = obj.b + feature * reward;
        obj.x_t = obj.A \ obj.b; obj.A_inv = inv(obj.A);
    end
end
end