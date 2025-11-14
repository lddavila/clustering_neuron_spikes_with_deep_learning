function [] = run_per_recording_simple_grouping(varargin)
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir)

config = spikesort_config();
%now we load the master training blind pass table which has various
%examples with various noise levels and accuracy
if length(varargin)<1
    blind_pass_table = importdata(config.FP_TO_MASTER_TRAINING_BP_TABLE);
else
    blind_pass_table = varargin{1};
end

unique_recordings = unique(blind_pass_table{:,"recording_name"});

dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"simple_grouping_per_recording"));
cd(dir_to_save_results_to);
for i=1:length(unique_recordings)
    c1 = blind_pass_table{:,"recording_name"}== unique_recordings(i);
    c2 = blind_pass_table{:,"accuracy"} >10;
    grouped_clusters = simple_grouping_parallel(blind_pass_table(c1 & c2,:),config);
    par_save("grouped_clusters_for_"+unique_recordings(i)+".mat",grouped_clusters)
end

end