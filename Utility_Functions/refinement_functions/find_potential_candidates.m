function [] = find_potential_candidates(blind_pass_table,options)
arguments
    blind_pass_table table
    options.max_number_candidates = Inf;
    options.max_euclidean_distance = 100;
end
locs_of_channels = get_probe_xy(); %get the x-y locations of the probe channels
for i=1:height(blind_pass_table)
    current_rep_wire_loc = locs_of_channels(rep_channel_1,:);
    distance_to_other_rep_wires = vecnorm(current_rep_wire_loc - locs_of_channels, 2, 2);
    nearby_wires = find(distance_to_other_rep_wires<options.max_euclidean_distance); %100 here is relative, it doesnt NEED to be this euclidean distance it can be more/less just depends on how you define close we may optimize this meta parameter later


    non_rep_wire_channels_nums = setdiff(nearby_wires,[rep_channel_1,rep_channel_2]);

    cell_array_of_compare_channels_for_current_rows{j} = non_rep_wire_channels_nums;
    cluster_peaks_idx = current_bp_table{j,"cluster_idx"}{1};
    cluster_labels = single(ones(size(peaks,2),1)); %default label everything to be unclustered
end
end