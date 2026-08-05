%%
a = importdata("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\testing_cluster_splitting_population_on_cluster\bp_graded_with_mean_wf.mat");

%%
grouped_clusters = simple_grouping_parallel_ensemble(a,config,false,'use_true_accuracy_instead_of_nn_filter',true);

%%
[cell_array_of_intersecting_peaks,cell_array_of_intersecting_channels,cell_arr_of_sw] = get_the_cluster_center_from_every_group(grouped_clusters,config);

%%
new_dict_fp = "C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\testing_cluster_splitting_population_on_cluster\new_dicts";

%% get config
config = spikesort_config;

%% import ts array
timestamps = importdata("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Data\1_600Neuron300SecondRecordingWithLevel1Noise\timestamps\timestamps.mat");
dir_with_channel_recordings = "C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Data\10_600Neuron300SecondRecordingWithLevel10Noise\recordings_by_channel";
spikes_per_channel_dir = "F:\all_pmv_10_600Neuron300SecondRecordingWithLevel10Noise_4_ch_07_19_2026\spikes_per_channel min_z_score 3";
spike_windows_dir = "F:\all_pmv_10_600Neuron300SecondRecordingWithLevel10Noise_4_ch_07_19_2026\spike_windows min_mult 3 num dps 60";
z_score_dir = "F:\all_pmv_10_600Neuron300SecondRecordingWithLevel10Noise_4_ch_07_19_2026\z_score";
new_results_dir = "C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\testing_cluster_splitting_population_on_cluster\clustering_results";

plot_dir = "C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\testing_cluster_splitting_population_on_cluster\plots_for_new_dimensions";

%% load the channel means and std
load("F:\all_pmv_10_600Neuron300SecondRecordingWithLevel10Noise_4_ch_07_19_2026\mean_and_std\mean_and_std.mat","channel_wise_means","channel_wise_std")
%% rerun clustering
for i=1:length(cell_array_of_intersecting_peaks)
    if isempty(cell_array_of_intersecting_peaks{i})
        continue;
    end
    pk_locs = cell_array_of_intersecting_peaks{i};
    channels = cell_array_of_intersecting_channels{i};
    try
        local_config = config;


        ir = calculate_input_range_for_raw_by_channel_ver_3(channels,dir_with_channel_recordings);
        ir = ir.';
        ordered_list_of_channels = strcat("c",string(channels),".mat");
        all_sw = get_lowest_bound_spike_windows_for_split_clust(ordered_list_of_channels,spikes_per_channel_dir,3,60,z_score_dir,spike_windows_dir,config);
        local_sw = [pk_locs-30,pk_locs+30,repelem(channels(1),length(pk_locs),1),pk_locs,repelem(min(config.DEFAULT_CLUSTERING_Z_SCORES),length(pk_locs),1)];
        % raw_cluster = get_raw(channels,dir_with_channel_recordings,config.NUM_DPTS_TO_SLICE,config.SCALE_FACTOR,min(config.DEFAULT_CLUSTERING_Z_SCORES),config,local_sw);
        cluster_idx = 1:1:size(local_sw,1);
        all_sw = [local_sw;all_sw];
        % curr_ts = timestamps(all_sw(:,4));
        [raw,samples,cluster_idx,curr_ts]= get_raw(channels,dir_with_channel_recordings,config.NUM_DPTS_TO_SLICE,config.SCALE_FACTOR,min(config.DEFAULT_CLUSTERING_Z_SCORES),config,all_sw,cluster_idx,timestamps);
        % curr_ts = curr_ts(new_locs).';
        cluster_idx = {cluster_idx};
        base_interp_raw = interpolate_spikes(raw, config);
        base_idxs = 1:max(size(base_interp_raw));
        base_aligned = align_to_peak_ver_2(base_interp_raw);
        peaks = get_peaks(base_aligned,true);

        general_peak_plotting_function(peaks,config,"channels",{channels},"cluster_idx",cluster_idx,"what_kind_of_data","peaks","pause_on_each_plot",false,"save_plots",true,"where_to_save",plot_dir,"save_name","new_tetrode"+string(i));
        nonzero_samples = samples(:,:,:);
        minpeaks = shiftdim(min(max(nonzero_samples),[],2),2);
        maxvals = shiftdim(max(min(nonzero_samples),[],2),2);
        admax_val = 32767;
        good_spike_filter = minpeaks < admax_val & maxvals > (-admax_val);
        good_spike_idx = find(good_spike_filter);
        current_filename = fullfile(new_results_dir,"Group_"+string(i));


        mean_of_relevant_channels =channel_wise_means(channels);

        std_dvns_of_relevant_channels = channel_wise_std(channels);
        tvals = mean_of_relevant_channels + (std_dvns_of_relevant_channels * config.NUM_OF_STD_ABOVE_MEAN) ;
        local_config.mutated_spike_windows = all_sw;
        run_spikesort_ntt_core_ver4(curr_ts,good_spike_idx,ir,tvals,current_filename,local_config,channels,all_sw,base_interp_raw,base_idxs);
    catch ME
        % disp(ME.getReport);
        % disp("accuracy of the cluster core is")
        % b = table({timestamps(pk_locs)},'VariableNames',["timestamps"]);
        % c = add_overlap_percentage_col_and_max_overlap_unit_optimized(b,config,timestamps);
        % d = add_accuracy_col_modified(config,c);
        % disp(d(:,["Max_Overlap_perc_With_Unit","Max_Overlap_Unit","accuracy"]));
    end
    disp("accuracy of the cluster core is")
    b = table({timestamps(pk_locs)},'VariableNames',["timestamps"]);
    c =  add_overlap_percentage_col_and_max_overlap_unit_optimized(b,config,timestamps);
    d = add_accuracy_col(config,c);
    disp(d(:,["Max_Overlap_perc_With_Unit","Max_Overlap_Unit","accuracy","tp","fp","fn"]));
end

















