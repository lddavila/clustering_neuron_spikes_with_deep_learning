function [] = get_drop_dimension_or_dont_data_set()
%set the path
home_dir = cd("..");
cd("..")
cd("..")
addpath(genpath(pwd))
cd(home_dir);
%get the config
config = spikesort_config();

%now get the table of best rep
if contains(pwd,"scratch2")
    table_of_best_rep = importdata(fullfile(config.base_file_path,"Data","test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise","DEBUG","table_of_best_rep.mat"));
    dictionaries_dir = fullfile(config.base_file_path,"Data","test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise","dictionaries multiplier 3 num_dps 60");
    ground_truth = importdata(fullfile(config.base_file_path,"Data","10_600Neuron300SecondRecordingWithLevel10Noise","ground_truth","ground_truth.mat"));
    dir_to_save_images_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"drop_dim_or_dont_images"));
else
    table_of_best_rep = importdata("E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\DEBUG\table_of_best_rep.mat");
    dictionaries_dir = "E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\dictionaries multiplier 3 num_dps 60";
    ground_truth = importdata("E:\10_600Neuron300SecondRecordingWithLevel10Noise\ground_truth\ground_truth.mat");
    dir_to_save_images_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"drop_dim_or_dont_images"));
end


%slice the table
sliced_table_of_best_rep =slice_table_for_parallel_processing(table_of_best_rep,"unit");
tol_amount = 6; %approximately .2 milliseconds
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = length(sliced_table_of_best_rep);
print_status_bar(num_iterations,"get_drop_dimension_or_dont_data_set.m");
parfor i=1:length(sliced_table_of_best_rep)
    try
        current_data = sliced_table_of_best_rep{i};
        current_data(current_data{:,"detection_ratio"} < 80,:) = [];
        current_data = sortrows(current_data,"mean_amplitude","descend");
        best_channel_for_current_unit = current_data{1,"all_channels"};
        all_tetrodes_which_contain_best_ch = find(any(config.ART_TETR_ARRAY==best_channel_for_current_unit,2));

        ground_truth_idxs = ground_truth{current_data{1,"unit"}};
        %for each tetrode get an image of all possible 2d projections for the
        %tetrode
        for j=1:length(all_tetrodes_which_contain_best_ch)
            current_tetrode = all_tetrodes_which_contain_best_ch(j);
            channels_of_current_tetrode = config.ART_TETR_ARRAY(current_tetrode,:);
            all_combos = nchoosek(1:4,2);
            all_save_names = repelem("",size(all_combos,1),1);
            for k=1:size(all_combos,1)
                all_save_names(k) = fullfile(dir_to_save_images_to,"unit_"+string(current_data{1,"unit"})+"_tetrode_"+string(current_tetrode)+"_channels_"+string(channels_of_current_tetrode(all_combos(k,1)))+"_"+string(channels_of_current_tetrode(all_combos(k,2)))+".jpeg") ;
            end
            if all(isfile(all_save_names))
                continue;
            end
            %import the appropriate data
            spike_data = load(fullfile(dictionaries_dir,"t"+string(current_tetrode)+" spike_tetrode_dictonary.mat"));
            spike_data = spike_data.data_to_save;
            spike_data = spike_data.spike_tetrode_dictionary;
            key = string(keys(spike_data));
            spike_data = spike_data(key);
            spike_windows = load(fullfile(dictionaries_dir,"t"+string(current_tetrode)+" sorted_spike_windows.mat"));
            spike_windows = spike_windows.data_to_save;
            spike_windows = spike_windows.sorted_spike_windows_for_current_tetrode_dictionary;
            spike_windows = spike_windows(key);

            interp_spikes = interpolate_spikes(spike_data, config);

            aligned = align_to_peak(interp_spikes);

            peaks = get_peaks(aligned,true);
            peak_locs = spike_windows(:,4);

            [~,which_spikes_belong_to_current_unit] = ismembertol(double(round(ground_truth_idxs)), double(round(peak_locs)),tol_amount,'DataScale',1);

            which_spikes_belong_to_current_unit(which_spikes_belong_to_current_unit==0) = [];
            for k=1:size(all_combos,1)
                % f =figure('Visible','off');
                name_for_figure = all_save_names(k);
                if ~isfile(fullfile(dir_to_save_images_to,name_for_figure))
                    f = figure;

                    x_data = peaks(all_combos(k,1),:);
                    y_data = peaks(all_combos(k,2),:);
                    cluster_x = x_data(which_spikes_belong_to_current_unit);
                    cluster_y = y_data(which_spikes_belong_to_current_unit);



                    scatter(x_data,y_data,1,[.7 .7 .7]);
                    hold on;
                    scatter(cluster_x,cluster_y,1,'k');
                    axis off
                    frame = getframe(f);
                    resized_binary_image = imresize(frame2im(frame),[512,512]);


                    imwrite(resized_binary_image,fullfile(dir_to_save_images_to,name_for_figure))

                    close(f);
                end
            end

        end

    catch
    end
    send(q,[]);
end
end