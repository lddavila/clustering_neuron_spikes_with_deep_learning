function y_iso = isotonic_regression_decreasing(y, w)
%ISOTONIC_REGRESSION_DECREASING  Post-hoc isotonic regression across thresholds.
%
% Enforces a monotone DECREASING sequence:
%   y_iso(1) >= y_iso(2) >= ... >= y_iso(end)
%
% Solves:
%   minimize sum_i w(i) * (y(i) - y_iso(i))^2
%   subject to monotone decreasing constraint.
%
% Inputs
%   y : Nx1 or 1xN vector of raw scores (e.g., predicted P(accuracy > t)).
%   w : (optional) Nx1 or 1xN vector of nonnegative weights. Default all ones.
%
% Output
%   y_iso : vector same size as y, monotone decreasing.

if nargin < 2 || isempty(w)
    w = ones(size(y));
end

% Work in column vectors internally
y = y(:);
w = w(:);

if any(w < 0) || any(~isfinite(w)) || any(~isfinite(y))
    error('y and w must be finite; w must be nonnegative.');
end

% To enforce decreasing, run increasing isotonic on -y, then flip sign back
y_iso_col = -isotonic_regression_increasing(-y, w);

% Return in original shape
y_iso = reshape(y_iso_col, size(y));
end


