% function [] = test_small_clustering_set_based_on_f1_scores(which_recording,varargin)
which_recording = 10;
which_cutting = "z score";
%meant to run on TACC and only TACC, not modified for anything else
%this function is meant to run the same examples, but uses the new spike
%detection method copied from ironclust
% STEP 1: Add functions to your path
home_dir = cd("..");
cd("..");
disp(pwd);
addpath(genpath(fullfile(pwd,"Utility_Functions")));
addpath(genpath(fullfile(pwd,"clustering-master")));
addpath(genpath(fullfile(pwd,"Grading_scripts")));
% addpath(fullfile(pwd,"startup.m"))
cd(home_dir);
disp("Finished Adding path")
default_dir_parts = ["_600Neuron300SecondRecordingWithLevel","Noise"];
currentPool = gcp('nocreate');
% if isempty(currentPool)
%     cluster = parcluster("Processes");
%     num_workers = max(1, floor(cluster.NumWorkers / 8));
%     fprintf("Have %i workers\n",num_workers);
%     time_start = tic();
%     poolobj = parpool(cluster, 3);
%     time_end = toc(time_start);
%     fprintf("Starting the parallel pool took %.2f seconds\n",time_end)
% end

beginning = which_recording;
the_end = which_recording+0.5;
number_of_channels_to_use = 4;
for k=1:length(number_of_channels_to_use)
    current_number_of_channels = number_of_channels_to_use(k);
    for i=beginning:the_end
        try
            config = spikesort_config();
            config.run_full_clustering = true;
            config.percentiles_to_use = [1];
            config.spikesort.NUM_ITERATIONS = 5;
            config.RECORDING_NAME = string(i)+default_dir_parts(1)+string(i)+default_dir_parts(2);
            config.ART_TETR_ARRAY = config.ART_TETR_ARRAY(197,:);
            if which_cutting=="ic"

                %overwrite the z scores
                config.DEFAULT_CLUSTERING_Z_SCORES = [1];
                config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"date_test_05_27_"+config.RECORDING_NAME+"_"+string(current_number_of_channels)+"_ch");
            else
                config.use_new_spike_detection = false;
                config.DEFAULT_CLUSTERING_Z_SCORES = [3];
                config.use_bandpass = false;
                config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"f1_clustering_tests_"+config.RECORDING_NAME);

            end



            %
            disp("Recording Name");
            disp(config.RECORDING_NAME)
            % config.prc_tile
            startup;
            %get a new art_tetrode_array and set it in the config
            % new_tetrode_array = build_channel_configs(current_number_of_channels,config);
            % config.ART_TETR_ARRAY = new_tetrode_array;
            if contains(pwd,"10595")
                config.GT_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
                config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
                config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"recordings_by_channel");
            elseif contains(pwd,"C:\Users\ldd77\")
                % ext_drive_fp = "F:";
                config.GT_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
                config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
                config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"recordings_by_channel");
            elseif contains(pwd,"E:\clustering_neuron_spikes_with_deep_learning")%running on inscopix
                ext_drive_fp = "E:";
                config.GT_FP = fullfile(ext_drive_fp,config.RECORDING_NAME,"ground_truth","ground_truth.mat");
                config.TIMESTAMP_FP = fullfile(ext_drive_fp,config.RECORDING_NAME,"timestamps","timestamps.mat");
                config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(ext_drive_fp,config.RECORDING_NAME,"recordings_by_channel");
            else

                config.GT_FP = fullfile(strrep(strrep(config.base_file_path,"cnheaton","afriedman"),"lddavila","afriedman"),"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
                config.TIMESTAMP_FP = fullfile(strrep(strrep(config.base_file_path,"cnheaton","afriedman"),"lddavila","afriedman"),"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
                config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(strrep(strrep(config.base_file_path,"cnheaton","afriedman"),"lddavila","afriedman"),"Data",config.RECORDING_NAME,"recordings_by_channel");
            end
            % (OPTIONAL STEP 2 CONTINUED) SET THE filepath of the ground truth files if your recording is simulated and they are available

            disp("Finished Setting directories")

            % Step 3: Download Necessary Data
            %run_me_to_download_data("10.7910/DVN/JWATDZ",config,true,config.RECORDING_NAME);
            disp("Finished Downloading Data");
            % Step 4: run the blind pass with a various min_z_score (cut threshold)
            very_beginning_time = tic;
            config.ground_truth_cell_array = importdata(config.GT_FP);
            config.debug_with_ground_truth = true;

            [blind_pass_table,fp_to_bp_table,config] = run_entire_clustering_algorithm_ver_2(config);


            end_time = toc(very_beginning_time);
            fprintf("Finished running blind pass it took %f seconds\n",end_time)
            % (OPTIONAL STEP 5 CONTINUED) Get max overlap unit and accuracy cols for the neurons
            % This is only possible if your recording is simulated and the ground truth
            % is provided
            % in this example the data is simulated and the ground truth is available
            beginning_time = tic;
            config.TIME_DELTA = 0.0002; %changing time delta to match kilosort4 delta used when computing matching score
            timestamps = importdata(config.TIMESTAMP_FP);
            if ~isfile(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"finished_adding_overlap_and_accuracy.txt"))
                blind_pass_table = add_overlap_percentage_col_and_max_overlap_unit_optimized(blind_pass_table,config,timestamps);
                blind_pass_table= add_accuracy_col(config,blind_pass_table);
                par_save(fp_to_bp_table,blind_pass_table);
            else
                disp("Overlap are already in your table.")
                disp("To recompute delete finished_adding_overlap_and_accuracy.txt");
            end
            disp("Finished Saving Accuracy");
            end_time = toc(beginning_time);
            fprintf("Finished adding overlap and accuracy columns it took %.2f seconds\n",end_time)

        catch ME
            disp(ME.getReport);
        end
    end
end
%% get the spike windows for the test set
spike_windows = load("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\f1_clustering_tests_10_600Neuron300SecondRecordingWithLevel10Noise\aligned_spike_windows\t1 sorted_spike_windows_after_purges.mat");
spike_windows = spike_windows.data_to_save;
% spike_windows_dict = spike_windows.sorted_spike_windows_for_current_tetrode_dictionary;
% the_key = string(keys(spike_windows_dict));
% spike_windows = spike_windows_dict(the_key);

%% import the aligned
aligned = load(blind_pass_table{1,"fp_to_aligned"});
aligned = aligned.data_to_save;
%% get the peaks
peaks = get_peaks(aligned,true);
%% get list of all channels
ordered_list_of_channels = strcat("c",string(1:384),".mat");
%% import the channel data
cell_array_of_channel_data = cell(length(ordered_list_of_channels),1);
channel_dir = config.DIR_WITH_OG_CHANNEL_RECORDINGS;
for i=1:length(ordered_list_of_channels)
    cell_array_of_channel_data{i} = importdata(fullfile(channel_dir,ordered_list_of_channels(i)));
    fprintf("Finished %i / %i\n", i, length(ordered_list_of_channels));
end

%% get the ground truth
ground_truth_cell_array = importdata(config.GT_FP);
%% create a directory to save all the images to
dir_to_save_images_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"splitting_cluster_tests_2"));


%% get timestamps to use
timestamps = importdata("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Data\1_600Neuron300SecondRecordingWithLevel1Noise\timestamps\timestamps.mat");
%% see if we can't split these clusters
close all;
% clc;
tol = 6; %equivalent to about .2 milliseconds
plot_type = ["whole tetrode","only cluster"];

for p=1:length(plot_type)
    plot_sep_folder = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_images_to,plot_type(p)));
    if plot_type(p)=="whole tetrode"
        sil_folder = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_images_to,"silhouette_plots"));
    end
    for i=8:height(blind_pass_table)
        start_string = sprintf("Running %i %s %i %i/ %i",blind_pass_table{i,"Z Score"},blind_pass_table{i,"Tetrode"},blind_pass_table{i,"Cluster"},i,height(blind_pass_table));

        rep_channel_1 =blind_pass_table{i,"rep_channel_1"}; %get the channel where the neuron appears clearest
        rep_channel_2 = blind_pass_table{i,"rep_channel_2"};
        non_rep_wire_channels = setdiff(ordered_list_of_channels,strcat("c"+string([rep_channel_1,rep_channel_2])+".mat")); %get channels to compare to
        non_rep_wire_channels_nums = setdiff(1:384,[rep_channel_1,rep_channel_2]);
        cluster_peaks_idx = blind_pass_table{i,"cluster_idx"}{1};
        rep_wire_peaks_1 = peaks(blind_pass_table{i,"rep_wire_1"},cluster_peaks_idx).'; %get the peaks as they appear on the best channel
        rep_wire_peaks_2 = peaks(blind_pass_table{i,"rep_wire_2"},cluster_peaks_idx).';

        % loc_of_cluster_peaks = spike_windows(blind_pass_table{i,"cluster_idx"}{1},4); %get what time those peaks appeared
        gt_locs = double(ground_truth_cell_array{blind_pass_table{i,"Max_Overlap_Unit"}});
        gt_ts = timestamps(gt_locs);
        [is_tp,loc_of_gt_in_peaks] = ismembertol(gt_ts,blind_pass_table{i,"timestamps"}{1},0.0002,'DataScale',1); %get the location of the peaks for the current cluster
        loc_of_gt_in_peaks(loc_of_gt_in_peaks==0) = []; %remove any peaks that do not have a match
        if isempty(loc_of_gt_in_peaks) || sum(is_tp)<10
            continue;
        end

        cluster_labels = zeros(size(peaks,2),1);
        cluster_labels(cluster_peaks_idx) = 1;
        unique_folder_name =create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(plot_sep_folder,blind_pass_table{i,"Z Score"}+" "+blind_pass_table{i,"Tetrode"}+" "+blind_pass_table{i,"Cluster"}));

        rearragned_channel_data = cell_array_of_channel_data(non_rep_wire_channels_nums);
        q = parallel.pool.DataQueue;
        afterEach(q,@print_status_bar)
        num_iterations = length(rearragned_channel_data);
        print_status_bar(num_iterations,start_string+" making comparisons figures ")


        og_sihlouette_score = silhouette(peaks([blind_pass_table{i,"rep_wire_1"},blind_pass_table{i,"rep_wire_2"}],:).',cluster_labels);
        % all_silhoutette_scores_for_new_channels = nan(length(og_sihlouette_score),length(rearragned_channel_data),1);
        rep_wire_data = peaks(blind_pass_table{i,"rep_wire_1"},:);
        parfor j=1:length(rearragned_channel_data)
            unique_code = " compared to channel "+string(str2double(strrep(strrep(non_rep_wire_channels(j),"c",""),".mat","")));
            save_name = fullfile(unique_folder_name,unique_code);


            compare_channel_data = rearragned_channel_data{j};
            other_tetrode_peaks_on_compare_channel = compare_channel_data(spike_windows(:,4)); %the same times of the peaks that we found on the other tetrode, but on this channel


            compare_channel_cluster_peaks = other_tetrode_peaks_on_compare_channel(cluster_peaks_idx); %get the cluster's appearence on this channel, we absolute cause peaks should be positive as we invert them
            all_silhoutette_scores_for_new_channels = silhouette([rep_wire_data.',other_tetrode_peaks_on_compare_channel],cluster_labels);
            if ~isfile(save_name+".png")
                %plot the og figure to compare to
                f = figure('units','normalized','outerposition',[0 0 1 1],'Visible','off');
                tiledlayout(1,2);
                nexttile();
                if plot_type(p) == "whole_tetrode"
                    scatter(peaks(blind_pass_table{i,"rep_wire_1"},:),peaks(blind_pass_table{i,"rep_wire_2"},:),3,"black","filled","DisplayName","All Of OG Tetrdoe"); %first plot the entire tetrode in a single color
                end
                hold on;
                scatter(rep_wire_peaks_1,rep_wire_peaks_2,3,"blue","filled","DisplayName","All Of OG Cluster"); %now plot the cluster in its own color
                scatter(peaks(blind_pass_table{i,"rep_wire_1"},cluster_peaks_idx(loc_of_gt_in_peaks)),peaks(blind_pass_table{i,"rep_wire_2"},cluster_peaks_idx(loc_of_gt_in_peaks)),3,"red","filled","DisplayName","Spikes that belong to max overlap unit"); %now plot only the spikes which belong to the max overlap unit identified through accuracy
                xlabel("Channel "+ string(rep_channel_1))
                ylabel("Channel "+string(rep_channel_2))

                legend;
                %now plot how the tetrode and cluster spikes would look if we used the other
                %dimension instead of the second best dimension
                nexttile()

                %plot all the spikes as they would appear if we had originally
                %created a tetrode with the original channel and the compare
                %channel

                if plot_type(p) == "whole_tetrode"
                    scatter(peaks(blind_pass_table{i,"rep_wire_1"},:),other_tetrode_peaks_on_compare_channel,3,"black","filled","DisplayName","All of OG tetrodes spikes projected with rep wire of og cluster and compare wire");
                end
                hold on;
                %plot the channel spikes as they would appear with the compare
                %channel
                scatter(peaks(blind_pass_table{i,"rep_wire_1"},cluster_peaks_idx),compare_channel_cluster_peaks,3,"blue","filled","DisplayName","All Of OG Cluster");
                %plot the ground truth spikes as they would appear given the
                %compare channel
                scatter(peaks(blind_pass_table{i,"rep_wire_1"},cluster_peaks_idx(loc_of_gt_in_peaks)),compare_channel_cluster_peaks(loc_of_gt_in_peaks),3,"red","filled","DisplayName","Spikes that belong to max overlap unit");
                % hold on;
                % scatter(rep_wire_peaks_1(loc_of_gt_in_peaks),other_channel_peaks(loc_of_gt_in_peaks),3,"red","filled","DisplayName","Only spikes max overlap unit");
                legend;

                % title();
                xlabel(string(rep_channel_1) +" (OG rep channel)")
                ylabel(string(str2double(strrep(strrep(non_rep_wire_channels(j),"c",""),".mat",""))+" (new compare channel)"))
                sgtitle(blind_pass_table{i,"Tetrode"} +unique_code)
                save_plots_in_all_formats(f,save_name)
                close(f);
                send(q,[]);
                % fprintf("%s finished %i / %i\n",start_string,j,length(non_rep_wire_channels))

            end

            if plot_type(p) == "whole tetrode"
                even_more_unique_folder_name =create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(sil_folder,blind_pass_table{i,"Z Score"}+" "+blind_pass_table{i,"Tetrode"}+" "+blind_pass_table{i,"Cluster"}));
                save_name = fullfile(even_more_unique_folder_name,unique_code);
                if ~isfile(save_name+".png")
                    f = figure('units','normalized','outerposition',[0 0 1 1],'Visible','on');
                    tiledlayout(1,2);
                    nexttile();
                    histogram(og_sihlouette_score,'BinEdges',-1:0.01:1)
                    title("OG Cluster Rep wire and second rep wire");xlabel("Sihloutte score");ylabel("Frequency")

                    nexttile();
                    histogram(all_silhoutette_scores_for_new_channels,'BinEdges',-1:0.01:1)

                    title("OG Cluster Rep wire and compare wire wire");xlabel("Sihloutte score");ylabel("Frequency")
                    sgtitle(blind_pass_table{i,"Tetrode"} +unique_code)
                    save_plots_in_all_formats(f,save_name)
                    close(f);
                end
                send(q,[]);
            end

        end

    end
end




