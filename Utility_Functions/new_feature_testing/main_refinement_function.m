function [] = main_refinement_function(blind_pass_table,config,options)
arguments
    blind_pass_table table
    config struct
    options.verbose = true;
end
%HELPER FUNCTIONS WE USE
% filter_candidates_based_on_cluster_avg_amp()
% filter_candidates_based_on_cluster_avg_prominance()
% find_potential_candidates()
% get_spike_windows_for_og_candidate()
% get_spike_windows_for_candidates()
% regrade_the_candidate     ()
% get_certainty_curve_for_cluster()
% run_refinement_pipeline()

sliced_table = slice_table_for_parallel_processing(blind_pass_table,[]);
parfor i=1:length(sliced_table)
    run_refinement_pipeline();
end
end