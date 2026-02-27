function [] = run_clustering_algorithm_on_desired_tetrodes_ver_3(channel_wise_means,channel_wise_std,number_of_std_above_means,dir_with_channel_recordings,dictionaries_dir,inital_tetrode_dir,initial_tetrodes_results_dir,config,current_z_score)
% disp("Beginning Core Clustering Algorithm")
list_of_available_dictionaries = struct2table(dir(fullfile(dictionaries_dir,"* tetrode_dictionary.mat")));
list_of_available_dictionaries = string(list_of_available_dictionaries{:,"name"});
list_of_available_tetrodes = strrep(list_of_available_dictionaries," tetrode_dictionary.mat","");
% list_of_available_tetrodes = "t1";


sliced_channel_wise_means = cell(size(list_of_available_tetrodes,2),1);
sliced_channel_stds = cell(size(list_of_available_tetrodes,2),1);

filenames = repelem("",1,length(list_of_available_tetrodes));
for j=1:length(list_of_available_tetrodes)
    filenames(j) =fullfile(inital_tetrode_dir,list_of_available_tetrodes(j)+".mat");
end
for i=1:length(list_of_available_tetrodes)
    current_tetrode = list_of_available_tetrodes(i);
    tetrode_dictionary = importdata(fullfile(dictionaries_dir,list_of_available_dictionaries(i)));
    tetrode_dictionary =tetrode_dictionary.tetrode_dictionary;

    channels_in_current_tetrode = tetrode_dictionary(current_tetrode);
    sliced_channel_wise_means{i} = channel_wise_means(channels_in_current_tetrode);
    sliced_channel_stds{i} = channel_wise_std(channels_in_current_tetrode);
end
list_of_available_channels = struct2table(dir(fullfile(config.DIR_WITH_OG_CHANNEL_RECORDINGS,"*.mat")));
config =parallel.pool.Constant(config);


% disp(config.DIR_WITH_OG_CHANNEL_RECORDINGS);
list_of_available_channels = string(list_of_available_channels{:,"name"});
list_of_available_channels = strrep(list_of_available_channels,".mat","");
list_of_available_channels = strrep(list_of_available_channels,"c","");
list_of_available_channels = str2double(list_of_available_channels);



% --- Stop any existing pool ---
% in the case of too much memory we dramatically resudce the number of
% workers 
% delete(gcp('nocreate'));  % 'nocreate' prevents error if no pool exists
% c =parcluster('local');
% parpool("Processes",min([c.NumWorkers,5]));
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = length(list_of_available_tetrodes);
print_status_bar(num_iterations,"run_clustering_algorithm_on_desired_tetrodes_ver_3: Z Score "+sprintf('%.2f',current_z_score)+".m")
%there should be a parfor on line 47 when not testing
parfor i=1:length(list_of_available_tetrodes)
    %get a local copy of config
    local_config = config.Value;

    
     
    % beginning_time = tic;
    current_tetrode = list_of_available_tetrodes(i);
    output_file_name = fullfile(initial_tetrodes_results_dir,current_tetrode+" output.mat");
    aligned_file_name = fullfile(initial_tetrodes_results_dir,current_tetrode+" aligned.mat");
    reg_ts_file_name= fullfile(initial_tetrodes_results_dir,current_tetrode+" reg_timestamps.mat");
    reg_ts_of_spikes_file_name =fullfile(initial_tetrodes_results_dir,current_tetrode+ " reg_timestamps_of_the_spikes.mat");
    peak_pcs_file_name = fullfile(initial_tetrodes_results_dir,current_tetrode+" peak_pcs.mat");

    %overwrite the field 
    local_config.peak_pcs_file_name = peak_pcs_file_name;

    c1 = isfile(output_file_name);
    c2 = isfile(aligned_file_name);
    c3 = isfile(reg_ts_file_name);
    c4 = isfile(reg_ts_of_spikes_file_name);
   
    if all([c1,c2,c3,c4])
        send(q,[]);
        continue;
    end

    %check for required files 
    %if all the necessary files weren't created in the previous step then
    %we cannot proceed to the next step
    c5 = isfile(fullfile(dictionaries_dir,current_tetrode+ " tetrode_dictionary.mat"));
    c6 = isfile(fullfile(dictionaries_dir,current_tetrode+" spike_tetrode_dictonary.mat"));
    c7 = isfile(fullfile(dictionaries_dir,current_tetrode+" timing_tetrode_dictionary.mat"));
    c8 = isfile(fullfile(dictionaries_dir,current_tetrode+" sorted_spike_windows.mat"));

    if ~all([c5,c6,c7,c8])
        send(q,[]);
        continue;
    end


    tetrode_dictionary = importdata(fullfile(dictionaries_dir,current_tetrode+ " tetrode_dictionary.mat"));
    tetrode_dictionary =tetrode_dictionary.tetrode_dictionary;
    % disp(fullfile(dictionaries_dir,current_tetrode+" spike_tetrode_dictonary.mat"));
    spike_tetrode_dictionary =importdata(fullfile(dictionaries_dir,current_tetrode+" spike_tetrode_dictonary.mat"));
    spike_tetrode_dictionary = spike_tetrode_dictionary.spike_tetrode_dictionary;
    timing_tetrode_dictionary =importdata(fullfile(dictionaries_dir,current_tetrode+" timing_tetrode_dictionary.mat"));
    timing_tetrode_dictionary =timing_tetrode_dictionary.timing_tetrode_dictionary;
    sorted_spike_windows_dictionary = importdata(fullfile(dictionaries_dir,current_tetrode+" sorted_spike_windows.mat"));
    sorted_spike_windows_dictionary = sorted_spike_windows_dictionary.sorted_spike_windows_for_current_tetrode_dictionary;
    sorted_spike_windows = sorted_spike_windows_dictionary(current_tetrode);



    %check to make sure that every channel in the current dataset is
    %actually available
    channels_in_current_tetrode = tetrode_dictionary(current_tetrode);
    all_channels_are_available = channels_in_current_tetrode==list_of_available_channels;
    if ~all(any(all_channels_are_available))
        send(q,[]);
        continue;
    end
    spike_tetrode_dictionary_samples_format =importdata(fullfile(dictionaries_dir,current_tetrode+" spike_tetrode_dictionary_samples_format.mat"));
    spike_tetrode_dictionary_samples_format = spike_tetrode_dictionary_samples_format.spike_tetrode_dictionary_samples_format;
    raw = spike_tetrode_dictionary(current_tetrode);

    %record raw's size before cutting
    raw_size_before = size(raw);

    %here we will implement the process that will allow us to save much
    %compute time in saving/loading
    %instead of getting new dictionaries for every threshold we will simply
    %apply the desired threshold indicated by the current_z_score variable
    
    %get the max peak value for each waveform
    max_peak_vals = max(raw,[],[1,3]).';
    %get which channel each max peak value belongs to
    which_channel = sorted_spike_windows(:,3);
    %get the appropriate filter value for the given channels and current
    %min_z_score
    
    flat_multipliers = cell2mat(local_config.Multipliers_in_mv);
    per_channel_thresholds_for_curr_z_sc= flat_multipliers(:,current_z_score);
    per_spike_thresholds = per_channel_thresholds_for_curr_z_sc(which_channel);
    has_already_been_run = check_if_current_data_has_already_been_run(max_peak_vals,which_channel,flat_multipliers,current_z_score,raw);
    if has_already_been_run
        continue;
    end
    %now filter out any values in raw that do not meet the threshold
    raw(:,max_peak_vals<per_spike_thresholds,:) = [];

    %get the new size of raw after the filter
    new_raw_size = size(raw);
    
    %we will continue if the new filter didn't affect the size because that
    %means the filter did not filter anything out and thus running it will
    %result clustering the exact same data again which would be wasted
    %compute time
    if all(new_raw_size==raw_size_before)
        % disp("No new data continuing ...")
        continue;
    end

    if isempty(raw)
        continue
    end


    raw_in_samples_format = spike_tetrode_dictionary_samples_format(current_tetrode);

    %repeat the same process with raw_in_samples_format
    raw_in_samples_format(:,:,max_peak_vals<per_spike_thresholds) = [];


    mean_of_relevant_channels =sliced_channel_wise_means{i};
    std_dvns_of_relevant_channels = sliced_channel_stds{i};

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
    ir = ir.';

    %ir = ir(:,1) - ir(:,2);
    tvals = mean_of_relevant_channels + (std_dvns_of_relevant_channels * number_of_std_above_means) ;



    % config = spikesort_config(); %load the config file;


    try
        %OG [output,aligned,reg_timestamps,reg_timestamps_of_the_spikes] = run_spikesort_ntt_core_ver4(raw,timestamps_for_current_tetrode,good_spike_idx,ir,tvals,filenames,config,channels_in_current_tetrode,i,sorted_spike_windows,initial_tetrodes_results_dir);
        [output,aligned,reg_timestamps,reg_timestamps_of_the_spikes,~] = run_spikesort_ntt_core_ver4(raw,timestamps_for_current_tetrode,good_spike_idx,ir,tvals,filenames,local_config,channels_in_current_tetrode,i,sorted_spike_windows,initial_tetrodes_results_dir,current_tetrode);
        %   - the first column contains the timestamps of the spikes in seconds
        %   - the second column contains the cluster classification of the spikes
        %       E.g., a value of '3' means that the spike belongs to cluster 3.
        if ~isempty(output) && ~isempty(aligned) && ~isempty(reg_timestamps)
            output = struct("output",output);
            aligned = struct("aligned",aligned);
            reg_timestamps = struct("reg_timestamps",reg_timestamps);
            reg_timestamps_of_the_spikes = struct("reg_timestamps_of_the_spikes",reg_timestamps_of_the_spikes);
            % peak_pcs = struct("peak_pcs",peak_pcs);
            

            par_save(output_file_name,output)
            par_save(aligned_file_name,aligned)
            par_save(reg_ts_file_name,reg_timestamps)
            par_save(reg_ts_of_spikes_file_name,reg_timestamps_of_the_spikes)
            

        else
            disp("Went into catch")
            send(q,[]);
            continue;
        end
    catch ME
        % end_time = toc(beginning_time);
        fprintf("\n")
        disp("########################################################################################")
        fprintf(2, "%s\n", getReport(ME, "extended", "hyperlinks", "off"));
        disp("########################################################################################")
        % fprintf('%s',ME.cause);
        send(q,[]);
        continue;
    end
    send(q,[]);
end
%once finished we can return to the standard amount of workers
% delete(gcp('nocreate'));  % 'nocreate' prevents error if no pool exists
%c =parcluster('local');
%parpool("Processes",min([c.NumWorkers,40]));
end