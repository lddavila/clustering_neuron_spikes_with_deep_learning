function [] = run_tp_fp_tn_fn_score_calculator_with_hyp_params(blind_pass_table,config)

sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,"recording_name");
all_possible_certainties = .95:-0.05:.50;
number_of_neural_nets_that_must_agree = 1:1:5;

dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"TP_FP_TN_FN_Results"));
for i=1:length(sliced_bp_table)

    current_data = sliced_bp_table{i};

    current_recording = current_data{1,"recording_name"};
    save_name = fullfile(dir_to_save_results_to,current_recording+".mat");
    if ~isfile(save_name)
        [tp_array,tn_array,fp_array,fn_array] = get_simple_grouping_tp_fp_tn_fn_scores(current_data,config,all_possible_certainties,number_of_neural_nets_that_must_agree);
        comparison_statistics = struct();
        comparison_statistics.tp_array = tp_array;
        comparison_statistics.tn_array = tn_array;
        comparison_statistics.fp_array = fp_array;
        comparison_statistics.fn_array = fn_array;
        par_save(save_name,comparison_statistics)
    end
end
end