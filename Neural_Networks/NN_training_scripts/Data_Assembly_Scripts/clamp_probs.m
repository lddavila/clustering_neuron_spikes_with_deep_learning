function p = clamp_probs(p)
% Prevent log(0) and numerical blowups
eps_val = 1e-7;
p = min(max(p, eps_val), 1 - eps_val);
end