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

%%
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
dir_to_save_images_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"splitting_cluster_tests_3"));


%% get timestamps to use
timestamps = importdata("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Data\1_600Neuron300SecondRecordingWithLevel1Noise\timestamps\timestamps.mat");
locs_of_channels = get_probe_xy(); %get the x-y locations of the probe channels
%% see if we can't split these clusters
close all;
% clc;
tol = 6; %equivalent to about .2 milliseconds
plot_type = ["whole tetrode","only cluster"];
plot_type = ["only cluster"];
cell_array_of_new_peak_vals_for_each_bp_table = cell(height(blind_pass_table),1);
cell_array_of_compare_channels = cell(height(blind_pass_table),1);
% array_of_og_rep_channel = blind_pass_table.rep_channel_1;
for p=1:length(plot_type)
    plot_sep_folder = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_images_to,plot_type(p)));

    sil_folder = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_images_to,"silhouette_plots"));

    for i=1:height(blind_pass_table)
        start_string = sprintf("Running %i %s %i %i/ %i",blind_pass_table{i,"Z Score"},blind_pass_table{i,"Tetrode"},blind_pass_table{i,"Cluster"},i,height(blind_pass_table));

        rep_channel_1 =blind_pass_table{i,"rep_channel_1"}; %get the channel where the neuron appears clearest
        rep_channel_2 = blind_pass_table{i,"rep_channel_2"};

        %get list of all channels within certain distance of current rep wire
        current_rep_wire_loc = locs_of_channels(rep_channel_1,:);
        distance_to_other_rep_wires = vecnorm(current_rep_wire_loc - locs_of_channels, 2, 2);
        nearby_wires = find(distance_to_other_rep_wires<100); %100 here is relative, it doesnt NEED to be this euclidean distance it can be more/less just depends on how you define close we may optimize this meta parameter later


        non_rep_wire_channels_nums = setdiff(nearby_wires,[rep_channel_1,rep_channel_2]);

        cell_array_of_compare_channels{i} = non_rep_wire_channels_nums;



        cluster_peaks_idx = blind_pass_table{i,"cluster_idx"}{1};
        rep_wire_peaks_1 = peaks(blind_pass_table{i,"rep_wire_1"},cluster_peaks_idx).'; %get the peaks as they appear on the best channel
        rep_wire_peaks_2 = peaks(blind_pass_table{i,"rep_wire_2"},cluster_peaks_idx).'; %get the peaks as they appear on the second best channel

        loc_of_cluster_peaks_on_ts_array = spike_windows(blind_pass_table{i,"cluster_idx"}{1},4); %get the index where the peaks of the current cluster appear on the timestamps array
        gt_locs_on_ts_array = double(ground_truth_cell_array{blind_pass_table{i,"Max_Overlap_Unit"}}); %get the index where the unit actually peaks on the timestamp array
        fn_idxs = setdiff(intersect(gt_locs_on_ts_array,spike_windows(:,4)),loc_of_cluster_peaks_on_ts_array); %get the spikes which belong to the ground truth unit, but weren't included in the cluster
        % gt_ts = timestamps(gt_locs);
        % [is_tp,loc_of_gt_in_peaks] = ismembertol(gt_ts,blind_pass_table{i,"timestamps"}{1},0.0002,'DataScale',1); %get the location of the peaks for the current cluster
        [~,loc_of_gt_in_peaks] = ismembertol(gt_locs_on_ts_array,loc_of_cluster_peaks_on_ts_array,tol,'DataScale',1); %find which spikes in the cluster belong to the unit
        loc_of_gt_in_peaks(loc_of_gt_in_peaks==0) = []; %remove any peaks that do not have a match in the cluster
        if isempty(loc_of_gt_in_peaks)
            continue;
        end

        cluster_labels = ones(size(peaks,2),1); %default label everything to be unclustered
        cluster_labels(cluster_peaks_idx) = 2;  %label the current cluster

        true_positive_idx = cluster_peaks_idx(loc_of_gt_in_peaks);
        false_positive_idx = setdiff(cluster_peaks_idx,true_positive_idx);



        idxs_of_cluster_data_we_aim_to_remove = false_positive_idx; %this is data that is in the cluster but not part of the ground truth unit, we'll remove it when calculating the ground truth silhouette/davies/calinski criterion
        cluster_labels_only_unit = ones(size(peaks,2),1); %create cluster labels that assume the false positive members of the current cluster do not exist
        cluster_labels_only_unit(true_positive_idx) = 2; %set only the spikes in the cluster that belong to the unit as part of the current cluster

        unique_folder_name =create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(plot_sep_folder,blind_pass_table{i,"Z Score"}+" "+blind_pass_table{i,"Tetrode"}+" "+blind_pass_table{i,"Cluster"})); %create a directory to store the plots

        rearragned_channel_data = cell_array_of_channel_data(non_rep_wire_channels_nums); %index the channel data so that we can run it in parallel while maintaining the channel labeling
        q = parallel.pool.DataQueue;
        afterEach(q,@print_status_bar)
        num_iterations = length(rearragned_channel_data);
        print_status_bar(num_iterations,start_string+" making comparisons figures ")


        unique_codes = strcat(" compared to channel ",string(non_rep_wire_channels_nums));

        even_more_unique_folder_name =create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(sil_folder,blind_pass_table{i,"Z Score"}+" "+blind_pass_table{i,"Tetrode"}+" "+blind_pass_table{i,"Cluster"}));
        second_save_name = fullfile(even_more_unique_folder_name,unique_codes);

        peaks_data_for_only_unit = peaks([blind_pass_table{i,"rep_wire_1"},blind_pass_table{i,"rep_wire_2"}],:).';
        og_peaks_data_size = size(peaks_data_for_only_unit,1);
        if ~all(isfile(second_save_name+".png"))

            %get the silhouette score assuming the full cluster
            og_sihlouette_score = silhouette(peaks([blind_pass_table{i,"rep_wire_1"},blind_pass_table{i,"rep_wire_2"}],:).',cluster_labels);

            %get the calinski & davies scores assuming the full cluster
            eva_cal= evalclusters(peaks([blind_pass_table{i,"rep_wire_1"},blind_pass_table{i,"rep_wire_2"}],:).',cluster_labels,"CalinskiHarabasz");
            eva_dav = evalclusters(peaks([blind_pass_table{i,"rep_wire_1"},blind_pass_table{i,"rep_wire_2"}],:).',cluster_labels,"DaviesBouldin");


            
            peaks_data_for_only_unit(intersect(1:og_peaks_data_size,idxs_of_cluster_data_we_aim_to_remove),:) = []; %filter out the fp of the cluster
            cluster_labels_only_unit(intersect(1:og_peaks_data_size,idxs_of_cluster_data_we_aim_to_remove)) = []; %filter out the labels of the fp

            eva_cal_only_unit= evalclusters(peaks_data_for_only_unit,cluster_labels_only_unit,"CalinskiHarabasz"); %only ground truth unit without rest of cluster
            eva_dav_only_unit = evalclusters(peaks_data_for_only_unit,cluster_labels_only_unit,"DaviesBouldin"); %only ground truth unit without rest of cluster
            only_unit_sihlouette_score = silhouette(peaks_data_for_only_unit,cluster_labels_only_unit); %only ground truth unit without rest of cluster
        end
        rep_wire_data = peaks(blind_pass_table{i,"rep_wire_1"},:);
        % rep_wire_data_without_fp = peaks(blind_pass_table{i,"rep_wire_1"},:);


        cell_array_of_other_channel_peaks = cell(length(rearragned_channel_data),1);
        



        for j=1:length(rearragned_channel_data)

            save_name = fullfile(unique_folder_name,unique_codes(j));


            compare_channel_data = rearragned_channel_data{j};
            other_tetrode_peaks_on_compare_channel = compare_channel_data(spike_windows(:,4)); %the same times of the peaks that we found on the other tetrode, but on this channel


            compare_channel_cluster_peaks = other_tetrode_peaks_on_compare_channel(cluster_peaks_idx); %get the cluster's appearence on this channel
            % all_silhoutette_scores_for_new_channels = silhouette([rep_wire_data.',other_tetrode_peaks_on_compare_channel],cluster_labels); %cluster and tetrode

            cell_array_of_other_channel_peaks{j} = [peaks(blind_pass_table{i,"rep_wire_1"},cluster_peaks_idx).',compare_channel_cluster_peaks];

            peaks_data_for_only_unit_on_new_ch = [rep_wire_data.',other_tetrode_peaks_on_compare_channel];
            peaks_data_for_only_unit_on_new_ch(intersect(1:og_peaks_data_size,idxs_of_cluster_data_we_aim_to_remove),:) = [];


            if ~all(isfile(second_save_name+".png"))
                all_silhoutette_scores_for_new_channels_only_unit = silhouette(peaks_data_for_only_unit_on_new_ch,cluster_labels_only_unit); %should be only the unit not the rest of the cluster


                eva_cal_on_compare_channel= evalclusters([rep_wire_data.',other_tetrode_peaks_on_compare_channel],cluster_labels,"CalinskiHarabasz");
                eva_dav_on_compare_channel = evalclusters([rep_wire_data.',other_tetrode_peaks_on_compare_channel],cluster_labels,"DaviesBouldin");
            end
            if ~isfile(save_name+".png")
                %plot the og figure to compare to
                f = figure('units','normalized','outerposition',[0 0 1 1],'Visible','off');
                tiledlayout(1,2);
                nexttile();
                if plot_type(p) == "whole tetrode"
                    scatter(peaks(blind_pass_table{i,"rep_wire_1"},:),peaks(blind_pass_table{i,"rep_wire_2"},:),3,"black","filled","DisplayName","All Of OG Tetrdoe"); %first plot the entire tetrode in a single color
                end
                hold on;
                scatter(rep_wire_peaks_1,rep_wire_peaks_2,3,"blue","filled","DisplayName","All Of OG Cluster"); %now plot the cluster in its own color
                scatter(peaks(blind_pass_table{i,"rep_wire_1"},cluster_peaks_idx(loc_of_gt_in_peaks)),peaks(blind_pass_table{i,"rep_wire_2"},cluster_peaks_idx(loc_of_gt_in_peaks)),3,"red","filled","DisplayName","Spikes that belong to max overlap unit in OG Cluster"); %now plot only the spikes which belong to the max overlap unit identified through accuracy
                xlabel("Channel "+ string(rep_channel_1))
                ylabel("Channel "+string(rep_channel_2))

                legend;
                %now plot how the tetrode and cluster spikes would look if we used the other
                %dimension instead of the second best dimension
                nexttile()

                %plot all the spikes as they would appear if we had originally
                %created a tetrode with the original channel and the compare
                %channel

                if plot_type(p) == "whole tetrode"
                    scatter(peaks(blind_pass_table{i,"rep_wire_1"},:).',other_tetrode_peaks_on_compare_channel,3,"black","filled","DisplayName","All of OG tetrodes spikes projected with rep wire of og cluster and compare wire");
                end
                hold on;
                %plot the channel spikes as they would appear with the compare
                %channel
                scatter(peaks(blind_pass_table{i,"rep_wire_1"},cluster_peaks_idx).',compare_channel_cluster_peaks,3,"blue","filled","DisplayName","All Of OG Cluster");
                %plot the ground truth spikes as they would appear given the
                %compare channel
                scatter(peaks(blind_pass_table{i,"rep_wire_1"},cluster_peaks_idx(loc_of_gt_in_peaks)).',compare_channel_cluster_peaks(loc_of_gt_in_peaks),3,"red","filled","DisplayName","Spikes that belong to max overlap unit");
                % hold on;
                % scatter(rep_wire_peaks_1(loc_of_gt_in_peaks),other_channel_peaks(loc_of_gt_in_peaks),3,"red","filled","DisplayName","Only spikes max overlap unit");
                legend;

                % title();
                xlabel(string(rep_channel_1) +" (OG rep channel)")
                ylabel(string(non_rep_wire_channels_nums(j))+" (new compare channel)")
                sgtitle(blind_pass_table{i,"Tetrode"} +unique_code)
                save_plots_in_all_formats(f,save_name)
                close(f);
                % send(q,[]);
                % fprintf("%s finished %i / %i\n",start_string,j,length(non_rep_wire_channels))

            end

            if plot_type(p) == "whole tetrode"

                if ~isfile(second_save_name+".png")
                    f = figure('units','normalized','outerposition',[0 0 1 1],'Visible','off');
                    tiledlayout("flow");
                    nexttile();
                    histogram(og_sihlouette_score,'BinEdges',-1:0.01:1,'Normalization','probability')
                    ylim([0,1]);
                    title_string = ["OG Cluster Rep wire and second rep wire",...
                        "Calinski Harabasz Criterion: "+sprintf("%.5f",eva_cal.CriterionValues),...
                        "Davies Bouldin Criterion: "+sprintf("%.5f",eva_dav.CriterionValues)];
                    title(title_string);xlabel("Sihloutte score");ylabel("Frequency")

                    nexttile()

                    histogram(only_unit_sihlouette_score,'BinEdges',-1:0.01:1,'Normalization','probability')
                    ylim([0,1]);
                    title("only TP of cluster")

                    nexttile();
                    histogram(all_silhoutette_scores_for_new_channels,'BinEdges',-1:0.01:1,'Normalization','probability','DisplayName',"Whole cluster")
                    ylim([0,1]);
                    % hold on;


                    title_string = ["OG Cluster Rep wire and second rep wire",...
                        "Calinski Harabasz Criterion: "+sprintf("%.5f",eva_cal_on_compare_channel.CriterionValues),...
                        "Davies Bouldin Criterion: "+sprintf("%.5f",eva_dav_on_compare_channel.CriterionValues)];
                    title(title_string);xlabel("Sihloutte score");ylabel("Frequency")

                    nexttile()
                    histogram(all_silhoutette_scores_for_new_channels_only_unit,'BinEdges',-1:0.01:1,'Normalization','probability','DisplayName',"Only Unit")
                    ylim([0,1]);
                    title("Only tp of the cluster")
                    sgtitle(blind_pass_table{i,"Tetrode"} +unique_code)
                    save_plots_in_all_formats(f,second_save_name)

                    legend;
                    close(f);
                end
                % send(q,[]);
            end
            send(q,[])
        end

        cell_array_of_new_peak_vals_for_each_bp_table{i} = cell_array_of_other_channel_peaks;
    end
end


%% now that we have the new peaks check which one we should use to maximize accuracy/splitting
plot_old_vs_new = true;
reclustered_plots = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_images_to,"reclustered_plots_rescale_double_new_dim"));
extended_blind_pass_table = cell(height(blind_pass_table),1);
cluster_addition = max(blind_pass_table.Cluster)+1;
cell_array_of_new_accuracies = cell(height(blind_pass_table),1);
cell_array_of_new_tables = cell(height(blind_pass_table),1);
for i=1:length(cell_array_of_new_peak_vals_for_each_bp_table)
    current_comparison_peaks = cell_array_of_new_peak_vals_for_each_bp_table{i};

    curr_comp_ch = cell_array_of_compare_channels{i};
    var_names = string(blind_pass_table.Properties.VariableNames);
    current_rows = cell2table(cell(0,5),'VariableNames',["Z Score","Tetrode","Cluster","timestamps","cluster_idx"]);
    current_z_score = blind_pass_table{i,"Z Score"};
    current_tetrode = blind_pass_table{i,"Tetrode"};
    
    accuracies_per_channel = cell(length(curr_comp_ch),1);
    tables_per_channel = cell(length(curr_comp_ch),1);
    for j=1:length(current_comparison_peaks)
        overall_title_string = sprintf("Z Score %s Tetrode %s Cluster %s Compared to channel %i",blind_pass_table{i,["Z Score","Tetrode","Cluster"]},curr_comp_ch(j));
        current_clustering_data = current_comparison_peaks{j};
        %current_clustering_data = zscore(current_clustering_data,1,1);
        current_clustering_data = rescale(current_clustering_data);
        current_clustering_data(:,2) = current_clustering_data(:,2)*2;
        % sihlouette_before = evalclusters(current_clustering_data,ones(size(current_clustering_data,1),1),"silhouette");
        % [epsilon,min_num_dpts,res_x] =find_epsilon_for_db_scan_using_k_distance(current_clustering_data,false,true);
        % new_clusters = dbscan(current_clustering_data,epsilon,min_num_dpts);
        % new_clusters = new_clusters+2; %we do this so the unclustered data is treated as a cluster and we can eval clusters
        sihlouette_after = evalclusters(current_clustering_data,'gmdistribution',"silhouette","KList",2:5,"ClusterPriors","equal");
        new_clusters = sihlouette_after.OptimalY;
        

        fprintf("Silhouette with k = %i %.2f\n",sihlouette_after.OptimalK,max(sihlouette_after.CriterionValues));
        unique_clusters = unique(new_clusters);
        new_cluster_idx = cell(length(unique_clusters),1);
        new_cluster_ts = cell(length(unique_clusters),1);
        for k=1:length(unique_clusters)
            old_cluster_ts = blind_pass_table{i,"timestamps"}{1};
            old_cluster_idx = blind_pass_table{i,"cluster_idx"}{1};
            new_cluster_ts{k} = old_cluster_ts(new_clusters==unique_clusters(k));
            new_cluster_idx{k} = old_cluster_idx(new_clusters==unique_clusters(k));
            cluster_addition = cluster_addition+1;
        end

        local_channels = repmat([blind_pass_table{i,"rep_channel_1"},cell_array_of_compare_channels{i}(j)],length(unique_clusters),1);
        new_table = table(repelem(current_z_score,length(unique_clusters),1), ...
            repelem(current_tetrode,length(unique_clusters),1), ...
            unique_clusters,...
            new_cluster_ts,...
            new_cluster_idx,...
            local_channels,...
            'VariableNames', ...
            ["Z Score","Tetrode","Cluster","timestamps","cluster_idx","channels"]);

        new_table_with_accuracy = add_overlap_percentage_col_and_max_overlap_unit_optimized(new_table,config,timestamps);
        new_table_with_accuracy = add_accuracy_col(config,new_table_with_accuracy);
        accuracies_per_channel{j} = new_table_with_accuracy.accuracy;
        tables_per_channel{j} = new_table_with_accuracy;
        % disp("old");
        % disp(blind_pass_table(i,["Z Score","Tetrode","Cluster","Max_Overlap_Unit","Max_Overlap_perc_With_Unit","accuracy","cluster_idx",]))
        % disp("___________________________________________________")
        % disp("new");
        % disp(new_table_with_accuracy(:,["Z Score","Tetrode","Cluster","Max_Overlap_Unit","Max_Overlap_perc_With_Unit","accuracy","cluster_idx",]))
        % % current_row = cell2table(blind_pass_table{i,"Z Score"},blind_pass_table{i,"Tetrode"},cluster_addition,'VariableNames',["Z Score","Tetrode","Cluster","timestamps","cluster_idx"]); 
        % disp("############################################################################")
        if plot_old_vs_new
            f = figure('units','normalized','outerposition',[0 0 1 1],'Visible','off');
            tiledlayout("flow");
            nexttile;
            scatter(current_clustering_data(:,1),current_clustering_data(:,2),3,"black","filled","DisplayName","All Of OG Cluster");
            legend();
            % title(sprintf("Silhouette before %.2f",sihlouette_before.CriterionValues))
            
            nexttile();
            new_cluster_idxs = unique(new_clusters);
            for k=1:length(new_cluster_idxs)
                if new_cluster_idxs(k)==-1
                    label = "Unclustered";
                else
                    label = "cluster " +string(new_cluster_idxs(k));
                end
                scatter(current_clustering_data(new_clusters==new_cluster_idxs(k),1),current_clustering_data(new_clusters==new_cluster_idxs(k),2),3,"filled","DisplayName",label);
                hold on;
            end
            legend
            title(sprintf("Silhouette after %.2f",max(sihlouette_after.CriterionValues)))

            sgtitle(overall_title_string);
            save_plots_in_all_formats(f,fullfile(reclustered_plots,overall_title_string));
            close(f);
            
        end

        fprintf("Finished %i / %i for bp row %i\n",j,length(current_comparison_peaks),i);
    end
    cell_array_of_new_accuracies{i} = accuracies_per_channel;
    cell_array_of_new_tables{i} = tables_per_channel;

end


%% compare old accuracies to new accuracies
for i=1:length(cell_array_of_new_accuracies)
    f = figure();
    % tiledlayout("flow");
    % nexttile()
    % bar(categorical("old accuracy"),blind_pass_table{i,"accuracy"})
    % ylim([0,100]);

    current_accuracies = cell_array_of_new_accuracies{i};
    max_size = max(cellfun(@length,current_accuracies));

    padded_accuracies = [];
    current_accuracies = [{blind_pass_table{i,"accuracy"}};current_accuracies];
    for j=1:length(current_accuracies)
       local_accuracies = current_accuracies{j};
       if size(local_accuracies,1) > size(local_accuracies,2)
           local_accuracies = local_accuracies.';
       end
       if length(local_accuracies) < max_size
           local_accuracies = [local_accuracies,zeros(1,max_size-length(local_accuracies))];
       end
       padded_accuracies = [padded_accuracies;local_accuracies];
    end

    
    % nexttile();
    comp_ch= cell_array_of_compare_channels{i};
    labels = categorical(["original accuracy";strcat("Channel ",string(comp_ch))]);
    labels = reordercats(labels,["original accuracy";strcat("Channel ",string(comp_ch))]);
    bar(labels,padded_accuracies,'grouped');
    hold on;
    yline(blind_pass_table{i,"accuracy"},"LineWidth",2,"Color",'red','Label',"Original cluster accuracy");
    ylim([0,100])
    title("Cluster "+string(i))
end

