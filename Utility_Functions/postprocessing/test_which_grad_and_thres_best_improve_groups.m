function [] = test_which_grad_and_thres_best_improve_groups()
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);
disp("Finished Setting Path");

config = spikesort_config();
config.GT_FP = fullfile(config.base_file_path,"Data","10_100","ground_truth","10_100Neuron300SecondRecordingWithLevel1Noise.h5.mat");
disp(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);
blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);
is_neuron_cond = blind_pass_table{:,"is_neuron"}==1;
blind_pass_table = blind_pass_table(is_neuron_cond,:);
disp("Finished Importing Blind Pass Table")

ground_truth = importdata(config.GT_FP);
disp("Finished importing GT")

gradience_levels_to_add = [1,2,3,4,5,6,7,8,9,10];
overlap_thresholds_to_try = [3,4,5,6,7,8,9,10];
status_table = [];

dir_to_save_to = fullfile(config.base_file_path,"under_unit_gradient_test");
cd(dir_to_save_to)
for i=1:size(gradience_levels_to_add,2)
    curr_gr_lvl = gradience_levels_to_add(i);
    for j=1:size(overlap_thresholds_to_try,2)
        curr_over_thresh = overlap_thresholds_to_try(j);
        table_of_gradience_and_threshold = add_various_cols_of_over_percentage_above_n(blind_pass_table,curr_gr_lvl,curr_over_thresh);
        gradience_key = string(table_of_gradience_and_threshold.Properties.VariableNames);
        list_of_levels = unique(table_of_gradience_and_threshold{:,1});
        blind_pass_table.(gradience_key) = table_of_gradience_and_threshold{:,gradience_key};
        for level_counter=1:size(list_of_levels,2)
            levels_to_filter = list_of_levels(1:level_counter);
            to_group_condition = blind_pass_table{:,gradience_key} ~= levels_to_filter(1);
            for cond_counter=2:size(levels_to_filter,2)
                to_group_condition = to_group_condition & blind_pass_table{:,gradience_key} ~= levels_to_filter(cond_counter); 
            end
            table_to_group = blind_pass_table(to_group_condition,:);
            results_of_grouping = determine_which_blind_pass_neurons_overlap_parallel(table_to_group,config);
            new_row = analyze_cluster_group_contamination(results_of_grouping,config,ground_truth,curr_gr_lvl,curr_over_thresh,levels_to_filter);
            status_table =[status_table;new_row];
            disp(status_table);

            writetable(status_table,'filename.txt','WriteMode','append');
        end
    end
end