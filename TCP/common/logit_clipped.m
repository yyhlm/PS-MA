function z = logit_clipped(p, epsilon)

if any(~isfinite(p), 'all')
    error('cmp:InvalidFeedback', 'Success values must be finite.');
end
p = min(max(p, epsilon), 1 - epsilon);
z = log(p) - log1p(-p);
end