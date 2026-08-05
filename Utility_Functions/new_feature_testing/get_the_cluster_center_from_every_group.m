function [cell_array_of_intersecting_peaks,cell_array_of_intersecting_channels,cell_array_of_spike_windows] = get_the_cluster_center_from_every_group(cluster_groups,config)
cell_array_of_intersecting_peaks = cell(length(cluster_groups),1);
cell_array_of_intersecting_channels = cell(length(cluster_groups),1);
cell_array_of_spike_windows = cell(length(cluster_groups),1);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
print_status_bar(length(cluster_groups),"get_the_cluster_center_from_every_group.m")
parfor i=1:length(cluster_groups)
    current_group = cluster_groups{i};
    current_group.fp_to_sorted_spike_windows_after_purges = strrep(current_group.fp_to_sorted_spike_windows_after_purges,"/scratch2/10595/lddavila/clustering_neuron_spikes_with_deep_learning/Default_Results_Dir/all_pmv_10_600Neuron300SecondRecordingWithLevel10Noise_4_ch_07_19_2026/aligned_spike_windows/","F:\all_pmv_10_600Neuron300SecondRecordingWithLevel10Noise_4_ch_07_19_2026\aligned_spike_windows\");
    current_group.fp_to_sorted_spike_windows_after_purges = strrep(current_group.fp_to_sorted_spike_windows_after_purges,"/",filesep);
    intersecting_pk_locs = [];
    intersecting_channels = [];
    intersecting_spike_windows_local = cell(height(current_group),1);
    for j=1:height(current_group)
        if j==1
            intersecting_pk_locs = importdata(current_group{j,"fp_to_sorted_spike_windows_after_purges"});
            local_spike_windows = intersecting_pk_locs(current_group{j,"cluster_idx"}{1},:);
            intersecting_pk_locs= intersecting_pk_locs(current_group{j,"cluster_idx"}{1},4);
            intersecting_spike_windows_local{j} = local_spike_windows;
            intersecting_channels = current_group{j,"channels"}{1};
        else
            local_pk_locs = importdata(current_group{j,"fp_to_sorted_spike_windows_after_purges"});
            local_spike_windows = local_pk_locs(current_group{j,"cluster_idx"}{1},:);
            local_pk_locs = local_pk_locs(current_group{j,"cluster_idx"}{1},4);
            [intersecting_pk_locs,i_a,i_b]= intersect(intersecting_pk_locs,local_pk_locs);
            intersecting_spike_windows_local{j} = local_spike_windows(i_b,:);
            intersecting_channels = union(intersecting_channels,current_group{j,"channels"}{1});
        end
    end
    all_sw = vertcat(intersecting_spike_windows_local{:});
    all_sw =sortrows(all_sw,4);
    cell_array_of_spike_windows{i} = all_sw;
    cell_array_of_intersecting_peaks{i} = intersecting_pk_locs;
    cell_array_of_intersecting_channels{i} = intersecting_channels;
    send(q,[]);
end
end