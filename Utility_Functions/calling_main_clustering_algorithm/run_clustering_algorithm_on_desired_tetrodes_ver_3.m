function [output_array,aligned_array,reg_timestamps_array] = run_clustering_algorithm_on_desired_tetrodes_ver_3(list_of_desired_tetrodes,channel_wise_means,channel_wise_std,number_of_std_above_means,dir_with_channel_recordings,dictionaries_dir,inital_tetrode_dir,initial_tetrodes_results_dir)
output_array = cell(1,length(list_of_desired_tetrodes));
aligned_array = cell(1,length(list_of_desired_tetrodes));
reg_timestamps_array= cell(1,length(list_of_desired_tetrodes));
filenames = repelem("",1,length(list_of_desired_tetrodes));
for j=1:length(list_of_desired_tetrodes)
    filenames(j) =fullfile(inital_tetrode_dir,list_of_desired_tetrodes(j)+".mat");
end
number_of_tetrodes_to_run = length(list_of_desired_tetrodes);
for i=1:length(list_of_desired_tetrodes)
    current_tetrode = list_of_desired_tetrodes(i);
    tetrode_dictionary = load(fullfile(dictionaries_dir,current_tetrode+ " tetrode_dictionary.mat"),"tetrode_dictionary");
    tetrode_dictionary =tetrode_dictionary.tetrode_dictionary;
    spike_tetrode_dictionary =load(fullfile(dictionaries_dir,current_tetrode+" spike_tetrode_dictonary.mat"),"spike_tetrode_dictionary");
    spike_tetrode_dictionary = spike_tetrode_dictionary.spike_tetrode_dictionary;
    timing_tetrode_dictionary =load(fullfile(dictionaries_dir,current_tetrode+" timing_tetrode_dictionary.mat"),"timing_tetrode_dictionary");
    timing_tetrode_dictionary =timing_tetrode_dictionary.timing_tetrode_dictionary;
    sorted_spike_windows_dictionary = load(fullfile(dictionaries_dir,current_tetrode+" sorted_spike_windows.mat"),"sorted_spike_windows_for_current_tetrode_dictionary");
    sorted_spike_windows_dictionary = sorted_spike_windows_dictionary.sorted_spike_windows_for_current_tetrode_dictionary;
    sorted_spike_windows = sorted_spike_windows_dictionary(current_tetrode);



    spike_tetrode_dictionary_samples_format =load(fullfile(dictionaries_dir,current_tetrode+" spike_tetrode_dictionary_samples_format.mat"),"spike_tetrode_dictionary_samples_format");
    spike_tetrode_dictionary_samples_format = spike_tetrode_dictionary_samples_format.spike_tetrode_dictionary_samples_format;
    channels_in_current_tetrode = tetrode_dictionary(current_tetrode);
    raw = spike_tetrode_dictionary(current_tetrode);
    if isempty(raw)
        continue
    end


    raw_in_samples_format = spike_tetrode_dictionary_samples_format(current_tetrode);


    mean_of_relevant_channels = channel_wise_means(channels_in_current_tetrode) ;
    std_dvns_of_relevant_channels = channel_wise_std(channels_in_current_tetrode);

    wire_filter = find_live_wires(raw);
    % wire_filter = [1 2 3 4];
    nonzero_samples = raw_in_samples_format(:,wire_filter,:);
    minpeaks = shiftdim(min(max(nonzero_samples),[],2),2);
    maxvals = shiftdim(max(min(nonzero_samples),[],2),2);
    admax_val = 32767;
    good_spike_filter = minpeaks < admax_val & maxvals > (-admax_val);
    good_spike_idx = find(good_spike_filter);
    % good_spike_idx = 1:size(raw,2);

    timestamps_for_current_tetrode = timing_tetrode_dictionary(current_tetrode);
    ir = calculate_input_range_for_raw_by_channel_ver_3(channels_in_current_tetrode,dir_with_channel_recordings);

    %ir = ir(:,1) - ir(:,2);
    tvals = mean_of_relevant_channels + (std_dvns_of_relevant_channels * number_of_std_above_means) ;


    config = spikesort_config(); %load the config file;


    % try
    %OG [output,aligned,reg_timestamps,reg_timestamps_of_the_spikes] = run_spikesort_ntt_core_ver4(raw,timestamps_for_current_tetrode,good_spike_idx,ir,tvals,filenames,config,channels_in_current_tetrode,i,sorted_spike_windows,initial_tetrodes_results_dir);
    [output,aligned,reg_timestamps,reg_timestamps_of_the_spikes] = run_spikesort_ntt_core_ver4(raw,timestamps_for_current_tetrode,good_spike_idx,ir,tvals,filenames,config,channels_in_current_tetrode,i,sorted_spike_windows,initial_tetrodes_results_dir);
    %   - the first column contains the timestamps of the spikes in seconds
    %   - the second column contains the cluster classification of the spikes
    %       E.g., a value of '3' means that the spike belongs to cluster 3.
    if ~isempty(output) && ~isempty(aligned) && ~isempty(reg_timestamps)
        output_array{i} = output;
        aligned_array{i} = aligned;
        reg_timestamps_array{i} = reg_timestamps;

        output = struct("output",output);
        aligned = struct("aligned",aligned);
        reg_timestamps = struct("reg_timestamps",reg_timestamps);
        reg_timestamps_of_the_spikes = struct("reg_timestamps_of_the_spikes",reg_timestamps_of_the_spikes);

        save(fullfile(initial_tetrodes_results_dir,current_tetrode+" output.mat"),"-fromstruct",output)
        save(fullfile(initial_tetrodes_results_dir,current_tetrode+" aligned.mat"),"-fromstruct",aligned)
        save(fullfile(initial_tetrodes_results_dir,current_tetrode+" reg_timestamps.mat"),"-fromstruct",reg_timestamps)
        save(fullfile(initial_tetrodes_results_dir,current_tetrode+ " reg_timestamps_of_the_spikes.mat"),"-fromstruct",reg_timestamps_of_the_spikes)

    else
        output_array{i} = NaN;
        aligned_array{i} = NaN;
        reg_timestamps_array{i} = NaN;

        continue;
    end
    disp("run_clustering_algorithm_on_desired_tetrodes_ver_3.m Finished "+ string(i)+"/"+string(length(number_of_tetrodes_to_run)))


end
end