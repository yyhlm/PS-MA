classdef TCPTSICFAlg
properties
    id
    mu
    covariance
    mu0
    Lambda
    Theta
end
methods
    function obj = TCPTSICFAlg(id, d, Theta)
        obj.id = id; obj.mu = zeros(d, 1); obj.covariance = eye(d);
        obj.mu0 = obj.mu; obj.Lambda = eye(d); obj.Theta = Theta;
    end
    function value = sample(obj)
        value = obj.mu + chol((obj.covariance + obj.covariance') / 2 + 1e-10 * eye(size(obj.covariance)), 'lower') * randn(size(obj.mu));
    end
    function obj = update(obj, reward, tasktype, r_t)
        feature = r_t - obj.Theta(:, tasktype); obj.mu0 = obj.mu; obj.Lambda = inv(obj.covariance);
        obj.covariance = inv(obj.Lambda + feature * feature'); obj.mu = obj.covariance * (obj.Lambda * obj.mu0 + feature * reward);
    end
end
end