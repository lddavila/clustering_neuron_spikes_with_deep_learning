function [new_data,new_pot_dims,cell_array_of_spike_windows] = find_new_dimension_candidates(blind_pass_table,config,options)
%this version picks the split dimension by channels with the highest
%amplitude for the cluster instead of rep wire like the original does
arguments
    blind_pass_table table                 %required
    config struct               %required
    options.bp_table_after_splitting cell = {} % Optional named argument
    options.plot_the_debug logical = false
end

% get timestamps to use
timestamps = importdata(config.TIMESTAMP_FP);
locs_of_channels = get_probe_xy(); %get the x-y locations of the probe channels

%add a reference id before slicing so we can rack
blind_pass_table.ref_id = (1:height(blind_pass_table)).';


%slice the blind pass table by their unique aligned files to minimize
%loading time
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,"fp_to_aligned");

%establish some structs which we'll be used to keep track of the peaks of
%the clusters we'll try to resplit
cell_array_of_new_peak_vals_for_each_bp_table_aligned_row = cell(length(sliced_bp_table),1);
cell_array_of_compare_channels_for_each_bp_table_aligned_row = cell(length(sliced_bp_table),1);
cell_array_of_spike_windows = cell(length(sliced_bp_table),1);

%get the ordered list of channels
ordered_list_of_channels = get_dynamic_ordered_list_of_channels(config);

%set up a dataqueue which will keep track of progress for us
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = length(ordered_list_of_channels);
print_status_bar(num_iterations,"split_clusters_with_alt_dimensions: loading channel data");

%Find and shut down any active parallel pool
existingPool = gcp('nocreate');
if ~isempty(existingPool)
    delete(existingPool);
end

%Start your new thread-based pool
parpool('threads');

% import the channel data which will be used by threads
cell_array_of_channel_data = cell(length(ordered_list_of_channels),1);
channel_dir = config.DIR_WITH_OG_CHANNEL_RECORDINGS;
parfor i=1:length(ordered_list_of_channels)
    cell_array_of_channel_data{i} = importdata(fullfile(channel_dir,ordered_list_of_channels(i)));
    send(q,[]);
end



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

    cell_array_of_spike_windows{i} = spike_windows;

    %load the aligned
    aligned = load(current_bp_table{1,"fp_to_aligned"});
    aligned = aligned.data_to_save;

    peaks = get_peaks(aligned,true);

    cell_array_of_new_peaks_for_current_rows = cell(height(current_bp_table),1);
    cell_array_of_compare_channels_for_current_rows = cell(height(current_bp_table),1);
    for j=1:height(current_bp_table)

        rep_channel_1 = current_bp_table{j,"ch_with_largest_pk_amp"}; %get the channel where the neuron appears clearest
        rep_channel_2 = current_bp_table{j,"ch_with_largest_pk_amp_2"};

        %get list of all channels within certain distance of current rep wire
        current_rep_wire_loc = locs_of_channels(rep_channel_1,:);
        distance_to_other_rep_wires = vecnorm(current_rep_wire_loc - locs_of_channels, 2, 2);
        nearby_wires = find(distance_to_other_rep_wires<50); %50 here is relative, it doesnt NEED to be this euclidean distance it can be more/less just depends on how you define close we may optimize this meta parameter later


        non_rep_wire_channels_nums = setdiff(nearby_wires,[current_bp_table{1,"channels"}{1}]);

        
        cluster_peaks_idx = current_bp_table{j,"cluster_idx"}{1};
      

        rearragned_channel_data = cell_array_of_channel_data(non_rep_wire_channels_nums); %index the channel data so that we can run it in parallel while maintaining the channel labeling

        cell_array_of_other_channel_peaks = cell(length(rearragned_channel_data),1);
        is_candidate_channel = false(length(rearragned_channel_data),1);
        for k=1:length(rearragned_channel_data)
            compare_channel_data = rearragned_channel_data{k};
            tetrode_peaks_on_compare_channel = compare_channel_data(spike_windows(:,4)); %the same times of the peaks that we found on the other tetrode, but on this channel
            compare_channel_cluster_peaks = tetrode_peaks_on_compare_channel(cluster_peaks_idx); %get the cluster's appearence on this channel

            mean_amplitude = mean(abs(compare_channel_cluster_peaks));
            if any(mean_amplitude >current_bp_table{j,"ch_amp"}{1})%check if the mean amplitude is higher/lower than the current channels
                cell_array_of_other_channel_peaks{k} = [peaks;tetrode_peaks_on_compare_channel.'];
                is_candidate_channel(k) = 1;
            end
        end
        cell_array_of_compare_channels_for_current_rows{j} = non_rep_wire_channels_nums(is_candidate_channel);
        cell_array_of_new_peaks_for_current_rows{j} = cell_array_of_other_channel_peaks;
    end
    cell_array_of_new_peak_vals_for_each_bp_table_aligned_row{i} = cell_array_of_new_peaks_for_current_rows;
    cell_array_of_compare_channels_for_each_bp_table_aligned_row{i} = cell_array_of_compare_channels_for_current_rows;
    send(q,[])
end

new_data = vertcat(cell_array_of_new_peak_vals_for_each_bp_table_aligned_row{:});
new_pot_dims = vertcat(cell_array_of_compare_channels_for_each_bp_table_aligned_row{:});
end