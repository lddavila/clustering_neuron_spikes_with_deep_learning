function nll = nll_from_logits_temp(z, y, T)
% Negative log-likelihood after temperature scaling using logits z.
% y in {0,1}
% calibrated probs
pT = 1 ./ (1 + exp(-(z ./ T)));
pT = clamp_probs(pT);

% NLL
nll = -mean(y .* log(pT) + (1 - y) .* log(1 - pT));
end
