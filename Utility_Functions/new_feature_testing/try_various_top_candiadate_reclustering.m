function [table_of_all_new_clusters] = try_various_top_candiadate_reclustering(new_clustering_data,blind_pass_table,config,cell_arr_of_sw,cell_array_of_channels,channel_wise_means,channel_wise_std,stage_dir)

dir_with_channel_recordings = config.DIR_WITH_OG_CHANNEL_RECORDINGS;
means_per_dimensions = cellfun(@mean, new_clustering_data,'UniformOutput',false);

how_many_top_candidates_to_use = [2,3,4,5,6];
bp_split_by_aligned = slice_table_for_parallel_processing(blind_pass_table,"fp_to_aligned");
%unique_aligned = unique(blind_pass_table{:,"fp_to_aligned"});
sw_map = containers.Map('KeyType','char','ValueType','any');
for j=1:length(bp_split_by_aligned)
    curr_bp = bp_split_by_aligned{j};
    sw_map(curr_bp{1,"fp_to_aligned"}) = cell_arr_of_sw{j};
end

timestamps = importdata(config.TIMESTAMP_FP);

plot_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"plots"));
cell_array_of_new_clusters_with_var_top_candidates = cell(length(how_many_top_candidates_to_use),1);
for k=1:length(how_many_top_candidates_to_use)
    curr_num_of_top_candidates_to_cluster_with = how_many_top_candidates_to_use(k);
    cell_array_of_new_clusters_created_using_old_as_guide = cell(height(blind_pass_table),1);
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    num_iterations = height(blind_pass_table);
    disp("Trying "+string(curr_num_of_top_candidates_to_cluster_with)+" dimensions")
    print_status_bar(num_iterations,sprintf("%i / %i finished",k,length(how_many_top_candidates_to_use)));
    pool = gcp('nocreate');

    if ~isempty(pool)
        delete(pool);
    end
    if contains(pwd,"10595")
        parpool(20)
    end
    for i=1:height(blind_pass_table)
        file_save_name = fullfile(stage_dir,sprintf("i_%i_k_%i.mat",i,k));
        if isfile(file_save_name)
            cell_array_of_new_clusters_created_using_old_as_guide{i} = importdata(file_save_name);
            send(q,[]);
            continue;
        end
        curr_means = [means_per_dimensions{i,1},means_per_dimensions{i,2}];

        if all(isnan(curr_means)) || length(curr_means) < curr_num_of_top_candidates_to_cluster_with
            send(q,[]);
            continue;
        end

        [~,sorted_idxs] = sort(curr_means,"descend");

        sw = sw_map(blind_pass_table{i,"fp_to_aligned"});

        new_results_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,string(length(blind_pass_table{i,"channels"}{1}))+"_ch"));

        % pk_locs = sw(blind_pass_table{i,"cluster_idx"}{1},4);
        pk_locs = sw(:,4);
        channels = [blind_pass_table{i,"channels"}{1},cell_array_of_channels{i}.'];

        channels = channels(sorted_idxs(1:curr_num_of_top_candidates_to_cluster_with));
        if isequal(channels,blind_pass_table{i,"channels"}{1})
            send(q,[])
            continue;
        end
        try
            local_config = config;


            ir = calculate_input_range_for_raw_by_channel_ver_3(channels,dir_with_channel_recordings);
            ir = ir.';
            ordered_list_of_channels = strcat("c",string(channels),".mat");
            % all_sw = get_lowest_bound_spike_windows_for_split_clust(ordered_list_of_channels,spikes_per_channel_dir,3,60,z_score_dir,spike_windows_dir,config);
            all_sw = [pk_locs-30,pk_locs+30,repelem(channels(1),length(pk_locs),1),pk_locs,repelem(min(config.DEFAULT_CLUSTERING_Z_SCORES),length(pk_locs),1)];
            % raw_cluster = get_raw(channels,dir_with_channel_recordings,config.NUM_DPTS_TO_SLICE,config.SCALE_FACTOR,min(config.DEFAULT_CLUSTERING_Z_SCORES),config,local_sw);
            cluster_idx = 1:1:size(all_sw,1);
            % all_sw = [local_sw;all_sw];
            % curr_ts = timestamps(all_sw(:,4));
            [raw,samples,cluster_idx,curr_ts]= get_raw(channels,dir_with_channel_recordings,config.NUM_DPTS_TO_SLICE,config.SCALE_FACTOR,min(config.DEFAULT_CLUSTERING_Z_SCORES),config,all_sw,cluster_idx,timestamps);
            % curr_ts = curr_ts(new_locs).';
            cluster_idx = {cluster_idx};
            base_interp_raw = interpolate_spikes(raw, config);
            base_idxs = 1:max(size(base_interp_raw));
            base_aligned = align_to_peak_ver_2(base_interp_raw);
            peaks = get_peaks(base_aligned,true);

            % general_peak_plotting_function(peaks,config,"channels",{channels},"cluster_idx",cluster_idx,"what_kind_of_data","peaks","pause_on_each_plot",false,"save_plots",true,"where_to_save",plot_dir,"save_name","new_tetrode"+string(i));
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
            local_config.current_channels = channels;
            [~, ~, ~,~,~,cleaned_clusters] = run_spikesort_ntt_core_ver4(curr_ts,good_spike_idx,ir,tvals,current_filename,local_config,channels,all_sw,base_interp_raw,base_idxs);
        catch
            send(q,[]);
            continue;
        end
        timestamps_for_clusters = cell(length(cleaned_clusters),1);
        old_key = strcat(strjoin(blind_pass_table{i,["Z Score","Tetrode","Cluster"]}," "));
        tetr_ts = timestamps(pk_locs);
        for p=1:length(timestamps_for_clusters)
            timestamps_for_clusters{p} = tetr_ts(cleaned_clusters{p});
        end
        new_bp_table = table(timestamps_for_clusters,cleaned_clusters,'VariableNames',["timestamps","cluster_idx"]);
        if config.has_ground_truth 
            new_bp_table =  add_overlap_percentage_col_and_max_overlap_unit_optimized(new_bp_table,config,timestamps,false,false);
            new_bp_table = add_accuracy_col(config,new_bp_table,false);
        end
        new_bp_table.ref_id = repelem(i,height(new_bp_table),1);
        new_bp_table.ref_string = repelem(old_key,height(new_bp_table),1);
        new_bp_table.channels = repmat({channels},height(new_bp_table),1);
        new_bp_table.num_of_candidates = repmat(curr_num_of_top_candidates_to_cluster_with,height(new_bp_table),1);
        cell_array_of_new_clusters_created_using_old_as_guide{i} = new_bp_table;
        par_save(file_save_name,new_bp_table);
        send(q,[]);
    end
    which_ones_to_concat = ~(cellfun(@isempty,cell_array_of_new_clusters_created_using_old_as_guide));
    cell_array_of_new_clusters_with_var_top_candidates{k} = vertcat(cell_array_of_new_clusters_created_using_old_as_guide{which_ones_to_concat});
end
which_have_something = ~(cellfun(@isempty,cell_array_of_new_clusters_with_var_top_candidates));
table_of_all_new_clusters = vertcat(cell_array_of_new_clusters_with_var_top_candidates{which_have_something});
end