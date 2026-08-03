function y = sigmoid_stable(x)

y = zeros(size(x));
positive = x >= 0;
y(positive) = 1 ./ (1 + exp(-x(positive)));
expX = exp(x(~positive));
y(~positive) = expX ./ (1 + expX);
end