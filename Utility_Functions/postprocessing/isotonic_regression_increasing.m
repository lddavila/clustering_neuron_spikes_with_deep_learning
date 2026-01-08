function x = isotonic_regression_increasing(y, w)
%ISOTONIC_REGRESSION_INCREASING  Weighted PAV for monotone increasing sequence.
% Enforces: x(1) <= x(2) <= ... <= x(n)
% Minimizes weighted squared error.

n = numel(y);

% Each point starts as its own "block"
v = y(:);          % block means
ww = w(:);         % block weights
startIdx = (1:n)'; % start index of each block
endIdx   = (1:n)'; % end index of each block
m = n;             % number of active blocks

i = 1;
while i < m
    % If monotonicity violated, merge blocks i and i+1
    if v(i) > v(i+1)
        newW = ww(i) + ww(i+1);
        newV = (ww(i)*v(i) + ww(i+1)*v(i+1)) / max(newW, eps);

        ww(i) = newW;
        v(i)  = newV;
        endIdx(i) = endIdx(i+1);

        % Remove block i+1 by shifting left
        ww(i+1:m-1) = ww(i+2:m);
        v(i+1:m-1)  = v(i+2:m);
        startIdx(i+1:m-1) = startIdx(i+2:m);
        endIdx(i+1:m-1)   = endIdx(i+2:m);
        m = m - 1;

        % After merging, step back to ensure previous monotonicity
        if i > 1
            i = i - 1;
        end
    else
        i = i + 1;
    end
    % fprintf("%i/%i\n",i,m);
end

% Expand blocks back out to full-length solution
x = zeros(n,1);
for k = 1:m
    x(startIdx(k):endIdx(k)) = v(k);
end
end