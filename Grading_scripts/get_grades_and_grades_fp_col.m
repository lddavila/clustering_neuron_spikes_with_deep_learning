function [blind_pass_table] = get_grades_and_grades_fp_col(blind_pass_table,config)
check_for_required_cols(blind_pass_table,["Z Score","Tetrode","fp_to_aligned"],"get_grades_and_grades_fp_col.m","Ensure that get_table_of_all_tetrodes_that_finished_blind_pass.m ran correctly.",0);
blind_pass_table = get_grades_for_nth_pass_of_clustering_ver_2(blind_pass_table,config);
end