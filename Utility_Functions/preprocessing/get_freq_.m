function [n1, n2, f] = get_freq_(N, sRateHz)
% [n1, n2, f] = get_freq_(N, sRateHz)
if mod(N,2)==0
    if nargin>=2
        df = sRateHz/N;
        f = df * [0:N/2, -N/2+1:-1]';
    end
    n1 = N/2+1;
else
    if nargin>=2
        df = sRateHz/N;
        f = df * [0:(N-1)/2, -(N-1)/2:-1]'; 
    end
    n1 = (N-1)/2+1;
end
n2 = N-n1;
end %func