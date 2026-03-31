function [] = check_unit_detection_while_clustering(filtered_spike_windows,current_tetrode,config,stage)

save_dir = fullfile(config.dir_to_save_debug_files_to,stage);
create_a_file_if_it_doesnt_exist_and_ret_abs_path(save_dir)
file_save_name = fullfile(save_dir,current_tetrode+"_mult_"+string(config.which_thresh)+".mat");
if ~isfile(file_save_name)
    table_of_best_rep = importdata(config.fp_to_table_of_best_rep);

    %filter down to only the tetrodes which match the current tetrode which
    %threshold is currently being used by the clustering algorithm
    current_tetrode_cond = table_of_best_rep{:,"tetrode"}==current_tetrode;
    current_thresh_cond = table_of_best_rep{:,"all_multiplier_idxs"}==config.which_thresh;
    filtered_table_of_best_rep = table_of_best_rep(current_thresh_cond & current_tetrode_cond,:);

    %now for all the units at this level determine the signal detection ratio
    peak_locs = filtered_spike_windows(:,4);
    det_rat_of_current_stage = zeros(height(filtered_table_of_best_rep),1);
    tol_amount = 6; %equates to approximately .2 milliseconds

    for i=1:height(filtered_table_of_best_rep)
        current_ground_truth_idxs = config.ground_truth_cell_array{filtered_table_of_best_rep{i,"unit"}};
        det_rat_of_current_stage(i)= (sum(ismembertol(double(round(current_ground_truth_idxs)), double(round(peak_locs)),tol_amount,'DataScale',1)) / length(current_ground_truth_idxs))*100;
    end
    filtered_table_of_best_rep.(stage) = det_rat_of_current_stage;
    par_save(file_save_name,filtered_table_of_best_rep);
end

end