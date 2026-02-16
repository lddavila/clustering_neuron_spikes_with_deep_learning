function [] = get_random_slice_of_channel_data(dir_with_raw_recordings,how_many_channels_to_plot,separate_plots,config)
%set random seed for reproducable results
rng(0);

%get a list of all files
table_of_all_files = struct2table(dir(fullfile(dir_with_raw_recordings,"*","**")));
table_of_all_files.name = string(table_of_all_files.name);
table_of_all_files.folder = string(table_of_all_files.folder);

%filter down to only .mat files
table_of_all_files(~contains(table_of_all_files{:,"name"},".mat"),:) = [];

%filter down to only the files whose folders are in the appropriate
%directory
only_channel_table = table_of_all_files(contains(table_of_all_files{:,"folder"},"recordings_by_channel"),:);

%group them by their recording
grouped_channels = slice_table_for_parallel_processing(only_channel_table,["folder"]);

desired_number_of_data_points = config.NUM_DPTS_TO_SLICE;
dir_to_save_channels_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"Random_channel_plots"));
for i=1:length(grouped_channels)
    current_data = grouped_channels{i};
    random_channel_samples = randperm(height(current_data),how_many_channels_to_plot);
    P_threshold = 6:1:15;
    for j=1:length(random_channel_samples)
        %figure;
        current_channel_data = importdata(fullfile(current_data{random_channel_samples(j),"folder"},current_data{random_channel_samples(j),"name"}));
        recording_dir = fullfile(current_data{random_channel_samples(j),"folder"});
        split_recording_dir = split(recording_dir,filesep);
        index_of_name = contains(split_recording_dir,"600Neuron300");
        recording_name = split_recording_dir(index_of_name);
        channel_number = strrep(current_data{random_channel_samples(j),"name"},".mat","");
        P = struct('spkThresh', [], 'qqFactor', P_threshold);
        [pk_locs,pk_vals,thresh_in_mv]= spikeDetectSingle_fast_(current_channel_data,P);

        f = figure;
        plot(current_channel_data(1:10000));
        title([strrep(strcat("Recording: ",recording_name),"_","\_"),strcat("Channel ",channel_number)]);
        ylabel("Microvolts");
        xlabel("Sample");
        hold on;
        scatter(pk_locs(pk_locs<10000),pk_vals(pk_locs<10000));
        for k=1:length(thresh_in_mv)
            yline(thresh_in_mv(k),"Label",sprintf("%.2f",thresh_in_mv(k)));
            yline(-1 *thresh_in_mv(k),"Label",sprintf("%.2f",-1*thresh_in_mv(k)));
        end
        save_plots_in_all_formats(f,fullfile(dir_to_save_channels_to,recording_name+"_"+channel_number))
        close(f)

        f = figure;
        first_10_k = pk_locs;
        spike_windows = zeros(length(first_10_k),2);
        raw_data = zeros(1,length(first_10_k),desired_number_of_data_points+1);
        for k=1:length(spike_windows)
            begining_of_spike = first_10_k(k) - fix(desired_number_of_data_points/2);
            spike_end = first_10_k(k) + fix(desired_number_of_data_points/2);
            raw_data(1,k,:)= current_channel_data(begining_of_spike:spike_end);
            
        end
        interpolated_spikes = interpolate_spikes(raw_data,config);
        aligned = align_to_peak(interpolated_spikes);
       
        plot(squeeze(aligned(1,1:100,:)).' *-1)

        % plot((1:desired_number_of_data_points+1).',   current_channel_data(current_spike_window(1):current_spike_window(2)));
        %     hold on;
        for k=1:length(thresh_in_mv)
            yline(thresh_in_mv(k),"Label",sprintf("%.2f",thresh_in_mv(k)));
            yline(-1 *thresh_in_mv(k),"Label",sprintf("%.2f",-1*thresh_in_mv(k)));
        end
        title([strrep(strcat("Recording: ",recording_name),"_","\_"),strcat("Channel ",channel_number)]);
        ylabel("Microvolts");
        xlabel("Sample");
        save_plots_in_all_formats(f,fullfile(dir_to_save_channels_to,recording_name+"_"+channel_number+"sliced_spikes"))
        close(f)
    end
end
end