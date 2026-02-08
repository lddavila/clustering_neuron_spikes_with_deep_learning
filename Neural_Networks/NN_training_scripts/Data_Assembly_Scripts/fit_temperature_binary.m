function T = fit_temperature_binary(p, y)
% Fits temperature T > 0 by minimizing NLL on a validation set.
% p : Nx1 uncalibrated probabilities for class 1
% y : Nx1 true labels in {0,1}

p = clamp_probs(p);

% Convert probs to logits
z = log(p) - log(1 - p);

% Objective: NLL of calibrated probabilities
obj = @(T) nll_from_logits_temp(z, y, T);

% Constrain T to a sensible range; expand if needed
T_lower = 0.05;
T_upper = 10.0;

% 1D bounded minimization
T = fminbnd(obj, T_lower, T_upper);
end