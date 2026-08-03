classdef PSMATCPAlg < handle

properties
    id = 0
    mu = 0
    covariance = 0
    mu0 = 0
    Lambda = 0
    Theta = 0
    count_arm = 0
    allreward_arm = 0
end

methods
    function obj = PSMATCPAlg(id, d, K, M, Theta)
        obj.id = id;
        obj.mu = zeros(d, 1);
        obj.covariance = eye(d);
        obj.mu0 = obj.mu;
        obj.Lambda = inv(obj.covariance);
        obj.Theta = Theta;
        obj.count_arm = zeros(K, M);
        obj.allreward_arm = zeros(K, M);
    end

    function x_t = sample(obj, stream)
                covariance = (obj.covariance + obj.covariance') / 2;
        factor = chol(covariance, 'lower');
        x_t = obj.mu + factor * randn(stream, numel(obj.mu), 1);
    end

    function obj = update(obj, reward, arm, tasktype, K, M, R_t)
        if reward == 0
            temp = obj.Lambda;
            for i = 1:K
                for j = 1:M
                    temp = temp + obj.count_arm(i, j) * ...
                        ((R_t(:, i) - obj.Theta(:, j)) * (R_t(:, i) - obj.Theta(:, j))');
                end
            end
            obj.covariance = inv(temp);
            temp = obj.Lambda * obj.mu0;
            for i = 1:K
                for j = 1:M
                    temp = temp + (R_t(:, i) - obj.Theta(:, j)) * obj.allreward_arm(i, j);
                end
            end
            obj.mu = obj.covariance * temp;
        else
            obj.count_arm(arm, tasktype) = obj.count_arm(arm, tasktype) + 1;
            obj.allreward_arm(arm, tasktype) = obj.allreward_arm(arm, tasktype) + reward;
            temp = obj.Lambda;
            for i = 1:K
                for j = 1:M
                    temp = temp + obj.count_arm(i, j) * ...
                        ((R_t(:, i) - obj.Theta(:, j)) * (R_t(:, i) - obj.Theta(:, j))');
                end
            end
            obj.covariance = inv(temp);
            temp = obj.Lambda * obj.mu0;
            for i = 1:K
                for j = 1:M
                    temp = temp + (R_t(:, i) - obj.Theta(:, j)) * obj.allreward_arm(i, j);
                end
            end
            obj.mu = obj.covariance * temp;
        end
    end
end
end