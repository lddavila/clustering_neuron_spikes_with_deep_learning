function [bin_counts] = get_bin_counts_per_rep_wire(peaks,num_channels)

bin_counts = cell(1,num_channels);
for i=1:num_channels
    % Set up the representative wire for the cluster
    [~, max_wire] = max(peaks, [], 1);
    poss_wires = unique(max_wire);
    n = histc(max_wire, poss_wires);
    [~, max_n] = max(n);
    compare_wire = poss_wires(max_n);
    wire_thresh = tvals(compare_wire);
    compare_peaks = peaks(compare_wire, :);
    [bin_counts{i},~] = histcounts(compare_peaks,'BinEdges',[-200:1:199,200]);
    peaks(compare_wire,:) = nan;
end

end