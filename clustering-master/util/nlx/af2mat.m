function matdata = af2mat(cf, raw, timestamps, save_data)
if nargin == 3
    save_data = false;
end
if iscell(cf)
    numclust = length(cf);
    clustnums = zeros(size(raw,2),1);
    for k = 1:numclust
        clustnums(cf{k}) = k;
    end
else
    clustnums = cf(:);
end

timestamps = timestamps(:);
% permute from wire X spike X sample to sample X wire X spike, then reshape
% to sample X spike to concatenate wires, and transpose to spike X sample:
if save_data
    matdata = [1e-6*timestamps clustnums ...
                reshape(permute(raw, [3 1 2]), [], size(raw,2)).' ];
else
    matdata = [1e-6*timestamps clustnums ];
    matdata(matdata(:, 2) == 0, :) = [];
end