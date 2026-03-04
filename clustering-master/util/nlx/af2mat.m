function the_matdata = af2mat(the_cluster_filter, the_raw, the_timestamps, the_save_data)
if nargin == 3
    the_save_data = false;
end
if iscell(the_cluster_filter)
    numclust = length(the_cluster_filter);
    clustnums = zeros(size(the_raw,2),1);
    for k = 1:numclust
        clustnums(the_cluster_filter{k}) = k;
    end
else
    clustnums = the_cluster_filter(:);
end

the_timestamps = the_timestamps(:);
% permute from wire X spike X sample to sample X wire X spike, then reshape
% to sample X spike to concatenate wires, and transpose to spike X sample:
if the_save_data
    the_matdata = [1e-6*the_timestamps clustnums ...
                reshape(permute(the_raw, [3 1 2]), [], size(the_raw,2)).' ];
else
    the_matdata = [1e-6*the_timestamps clustnums ];
    the_matdata(the_matdata(:, 2) == 0, :) = [];
end