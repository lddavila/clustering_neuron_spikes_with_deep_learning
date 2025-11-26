function [X_norm, mu, sig] = safe_zscore_normalizer(X)
mu = mean(X,1);
sig = std(X,[],1);

% Replace zeros in std with 1 to avoid division by zero
sig(sig == 0) = 1;

X_norm = (X - mu) ./ sig;

% Optional: if entire column is zero, keep it zero
zero_var_cols = std(X,[],1) == 0;
X_norm(:, zero_var_cols) = 0;
end