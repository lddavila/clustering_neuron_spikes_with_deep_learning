function [cell_array_of_intersecting_peaks] = get_the_cluster_center_from_every_group(cluster_groups,config)
cell_array_of_intersecting_peaks = cell(length(cluster_groups),1);
for i=1:length(cluster_groups)
    current_group = cluster_groups{i};
    current_group.fp_to_sorted_spike_windows_after_purges = strrep(current_group.fp_to_sorted_spike_windows_after_purges,"/scratch2/10595/lddavila/clustering_neuron_spikes_with_deep_learning/Default_Results_Dir/all_pmv_10_600Neuron300SecondRecordingWithLevel10Noise_4_ch_07_19_2026/aligned_spike_windows/","F:\all_pmv_10_600Neuron300SecondRecordingWithLevel10Noise_4_ch_07_19_2026\aligned_spike_windows\");
    current_group.fp_to_sorted_spike_windows_after_purges = strrep(current_group.fp_to_sorted_spike_windows_after_purges,"/",filesep);
    intersecting_pk_locs = [];
    for j=1:height(current_group)
        if j==1
            intersecting_pk_locs = importdata(current_group{i,"fp_to_sorted_spike_windows_after_purges"});
            intersecting_pk_locs = intersecting_pk_locs(current_group{i,"cluster_idx"}{1},4);
        else
            local_pk_locs = importdata(current_group{i,"fp_to_sorted_spike_windows_after_purges"});
            local_pk_locs = local_pk_locs(current_group{i,"cluster_idx"}{1},4);
            intersecting_pk_locs = intersect(intersecting_pk_locs,local_pk_locs);
        end
    end
    cell_array_of_intersecting_peaks{i} = intersecting_pk_locs;
end
end