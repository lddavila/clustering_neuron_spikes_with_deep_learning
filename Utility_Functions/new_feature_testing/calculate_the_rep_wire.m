function [compare_wire,compare_channel] = calculate_the_rep_wire(peaks,channels)
% Set up the representative wire for the cluster
[~, max_wire] = max(peaks, [], 1);
poss_wires = unique(max_wire);
n = histc(max_wire, poss_wires);
[~, max_n] = max(n);
compare_wire = poss_wires(max_n);
compare_channel = channels(compare_wire);
end