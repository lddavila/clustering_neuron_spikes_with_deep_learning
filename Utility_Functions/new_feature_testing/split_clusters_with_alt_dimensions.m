function [blind_pass_table] = split_clusters_with_alt_dimensions(blind_pass_table,config,varargin)
% get timestamps to use
timestamps = importdata(config.TIMESTAMP_FP);
locs_of_channels = get_probe_xy(); %get the x-y locations of the probe channels
cell_array_of_new_peak_vals_for_each_bp_table = cell(height(blind_pass_table),1);
cell_array_of_compare_channels = cell(height(blind_pass_table),1);

%slice the blind pass table by their unique aligned files to minimize
%loading time
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,"fp_to_aligned");

%get the ordered list of channels
ordered_list_of_channels = get_dynamic_ordered_list_of_channels(config);

% import the channel data which will be used by threads
cell_array_of_channel_data = cell(length(ordered_list_of_channels),1);
channel_dir = config.DIR_WITH_OG_CHANNEL_RECORDINGS;
%set up a dataqueue which will keep track of progress for us
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = length(ordered_list_of_channels);
print_status_bar(num_iterations,"split_clusters_with_alt_dimensions: loading channel data");

parfor i=1:length(ordered_list_of_channels)
    cell_array_of_channel_data{i} = importdata(fullfile(channel_dir,ordered_list_of_channels(i)));
    send(q,[]);
end

%Find and shut down any active parallel pool
existingPool = gcp('nocreate');
if ~isempty(existingPool)
    delete(existingPool);
end

%Start your new thread-based pool
parpool('threads');

%set up a dataqueue which will keep track of progress for us
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = length(sliced_bp_table);
print_status_bar(num_iterations,"split_clusters_with_alt_dimensions: getting split data");


for i=1:length(sliced_bp_table)

    %get current table
    current_bp_table = sliced_bp_table{i};

    %load the sw
    spike_windows = load(current_bp_table{1,"fp_to_sorted_spike_windows_after_purges"});
    spike_windows = spike_windows.data_to_save;

    %load the aligned
    aligned = load(current_bp_table{1,"fp_to_aligned"});
    aligned = aligned.data_to_save;

    peaks = get_peaks(aligned,true);

    all_sil_scores = cell(height(current_bp_table),1);
    all_davies_scores = nan(height(current_bp_table),1);
    all_calinski_scores = nan(height(current_bp_table),1);

    warning('off', 'stats:pdist2:DataConversion'); %known warning which will not affect result
    for j=1:height(current_bp_table)

        rep_channel_1 =current_bp_table{j,"rep_channel_1"}; %get the channel where the neuron appears clearest
        rep_channel_2 = current_bp_table{j,"rep_channel_2"};

        %get list of all channels within certain distance of current rep wire
        current_rep_wire_loc = locs_of_channels(rep_channel_1,:);
        distance_to_other_rep_wires = vecnorm(current_rep_wire_loc - locs_of_channels, 2, 2);
        nearby_wires = find(distance_to_other_rep_wires<100); %100 here is relative, it doesnt NEED to be this euclidean distance it can be more/less just depends on how you define close we may optimize this meta parameter later


        non_rep_wire_channels_nums = setdiff(nearby_wires,[rep_channel_1,rep_channel_2]);

        cell_array_of_compare_channels{i} = non_rep_wire_channels_nums;
        cluster_peaks_idx = current_bp_table{j,"cluster_idx"}{1};
        cluster_labels = single(ones(size(peaks,2),1)); %default label everything to be unclustered
        cluster_labels(cluster_peaks_idx) = 2;  %label the current cluster

        rearragned_channel_data = cell_array_of_channel_data(non_rep_wire_channels_nums); %index the channel data so that we can run it in parallel while maintaining the channel labeling

        peaks_data_for_cluster = single(peaks([current_bp_table{j,"rep_wire_1"},current_bp_table{j,"rep_wire_2"}],:).');
        


        %get the silhouette score assuming the full cluster
        all_sil_scores{j} = silhouette(peaks_data_for_cluster,cluster_labels);

        

        %get the calinski & davies scores assuming the full cluster
        eva_cal= evalclusters(peaks_data_for_cluster,cluster_labels,"CalinskiHarabasz");
        all_calinski_scores(j) = eva_cal.CriterionValues;
        eva_dav = evalclusters(peaks_data_for_cluster,cluster_labels,"DaviesBouldin");
        all_davies_scores(j) = eva_dav.CriterionValues;


        cell_array_of_other_channel_peaks = cell(length(rearragned_channel_data),1);


        for k=1:length(rearragned_channel_data)
            compare_channel_data = rearragned_channel_data{k};
            other_tetrode_peaks_on_compare_channel = compare_channel_data(spike_windows(:,4)); %the same times of the peaks that we found on the other tetrode, but on this channel
            compare_channel_cluster_peaks = other_tetrode_peaks_on_compare_channel(cluster_peaks_idx); %get the cluster's appearence on this channel
            cell_array_of_other_channel_peaks{k} = [peaks(blind_pass_table{i,"rep_wire_1"},cluster_peaks_idx).',compare_channel_cluster_peaks];
        end
        cell_array_of_new_peak_vals_for_each_bp_table{i} = cell_array_of_other_channel_peaks;

        
    end
    current_bp_table.calinski_score = all_calinski_scores;
    current_bp_table.sil_score = all_sil_scores;
    current_bp_table.davies_score = all_davies_scores;
    sliced_bp_table{i} = current_bp_table;
    send(q,[])
end
end