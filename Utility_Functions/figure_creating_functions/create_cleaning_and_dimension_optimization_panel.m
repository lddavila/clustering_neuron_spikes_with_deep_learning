% set up enviornment
[config,figure_dir] = set_up_figure_creation("create_cleaning_and_dimension_optimization_panel");

%% load data
bp_2_ch = load(fullfile(config.base_file_path, "Data","data_for_poster_figs","blind_pass_table_2_ch.mat"));
bp_2_ch = bp_2_ch.data_to_save;
%% filter down to "bad" examples to display how we can improve them
only_bad = bp_2_ch(bp_2_ch.accuracy<50,:);

%% 
number_of_surrounding_candidates_to_check = 4;
for i=1:height(only_bad)
    curr_aligned_fp = only_bad{i,"fp_to_aligned"};
    curr_sw_fp = only_bad{i,"fp_to_sorted_spike_windows_after_purges"};
    candidates = 
end
%% hard code the number that has the exact projection we desire
