function [] = get_all_overlap_for_all_units_in_a_gt_file(fp_to_gt,file_save_name,config,dir_with_channel_data)
config.parent_save_dir = "F:";
save_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,file_save_name));
gt = importdata(fp_to_gt);
min_amp = 80;
for i=1:length(gt)
    ground_truth_idxs = gt{i};
    table_of_ratios = check_which_channels_best_represent_ground_truth(dir_with_channel_data,ground_truth_idxs,min_amp);
    par_save(fullfile(save_dir,"Unit_"+string(i)),table_of_ratios);
    fprintf("Finished %i/%i\n",i,length(gt));
end
end