function pT = apply_temperature_binary(p, T)
% Applies temperature scaling to binary probabilities.
p = clamp_probs(p);
z = log(p) - log(1 - p);
pT = 1 ./ (1 + exp(-(z ./ T)));
end