function [new_clusters] = recluster_by_amplitude_wrapper(blind_pass_table,config,channel_wise_means,channel_wise_std,varargin)
num_ch = length(blind_pass_table{1,"channels"}{1});
if ~isempty(varargin)
    stage_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"splitting_cluster_by_amp")+strjoin(varargin{1},"_"));
else
    stage_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"splitting_cluster_by_amp"));
end
blind_pass_table = add_highest_amplitude_channel_col(blind_pass_table,config);
blind_pass_table = add_amplitude_per_channel_col(blind_pass_table);
blind_pass_table.ref_id = (1:height(blind_pass_table)).';
disp(stage_dir);
bp_table_after_splitting_save_name = fullfile(stage_dir,"tetrode_peaks_with_new_dims_"+string(num_ch)+"_ch.mat");
disp(bp_table_after_splitting_save_name);
if ~isfile(bp_table_after_splitting_save_name)
    [new_data,new_pot_dims,cell_arr_of_sw] = find_new_dimension_candidates(blind_pass_table,config,'plot_the_debug',false);
    data_struct = struct();
    data_struct.new_peaks = new_data;
    data_struct.new_dims = new_pot_dims;
    data_struct.sw = cell_arr_of_sw;
    par_save(bp_table_after_splitting_save_name,data_struct);
    disp("Successfully obtained the split table")
else
    data_struct = load(bp_table_after_splitting_save_name);
    data_struct = data_struct.data_to_save;
    new_data = data_struct.new_peaks;
    new_pot_dims = data_struct.new_dims;
    cell_arr_of_sw = data_struct.sw;
    disp("Successfully loaded the split table")
end
[old_peaks,only_new_peaks] = assemble_new_tetrode_peaks_and_pcs(blind_pass_table,new_data,new_pot_dims);
config.run_full_clustering = true;
config.debug_with_ground_truth = false;


new_clusters_fn = fullfile(stage_dir,"new_clusters.mat");
if ~isfile(new_clusters_fn)
    new_clusters = try_various_top_candiadate_reclustering([old_peaks,only_new_peaks],blind_pass_table,config,cell_arr_of_sw,new_pot_dims,channel_wise_means,channel_wise_std,stage_dir);
    par_save(new_clusters_fn,new_clusters);
else
    new_clusters = importdata(new_clusters_fn);
end

vars_to_include = setdiff(string(blind_pass_table.Properties.VariableNames),["grades","timestamps","cluster_idx","channels","Cluster","mean_waveform_rep_wire_1","mean_waveform_rep_wire_2","mean_waveform_rep_wire_3","mean_waveform_rep_wire_4","overlap_perc_with_all_units","rep_wire_2","tp","fp","fn","accuracy","Max_Overlap_perc_With_Unit","Max_Overlap_Unit","ch_with_largest_pk_amp","ch_with_largest_pk_amp_2"]);

new_clusters = join(new_clusters,blind_pass_table(:,vars_to_include),"Keys","ref_id");

new_clusters = add_highest_amplitude_channel_col(new_clusters);
% map_bp_table_to_reclustered_rows(blind_pass_table,new_clusters)
end