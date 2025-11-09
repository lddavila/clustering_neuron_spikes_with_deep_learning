function [tracked_faliures] = get_grouping_for_specific_unit_and_recording(varargin)
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);
config = spikesort_config();
if length(varargin)<1
    blind_pass_table = importdata(config.FP_TO_MASTER_TRAINING_BP_TABLE);
else
    blind_pass_table = varargin{1};
end
unit = unique(blind_pass_table{:,"Max_Overlap_Unit"}).';

unique_recording_list = unique(blind_pass_table{:,"recording_name"});
dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"get_grouping_fails"));
cd(dir_to_save_results_to);
min_accuracy = 12;
for i=1:length(unique_recording_list)
    c1 = blind_pass_table{:,"recording_name"}==unique_recording_list(i);
    c2 = blind_pass_table{:,"Max_Overlap_Unit"}==unit;
    if size(c2,2)>1
        c2 = any(c2,2);
    end
    c3 = blind_pass_table{:,"accuracy"} >=min_accuracy;

    full_table = blind_pass_table(c1 & c3 & c2,:);
    disp(full_table(:,["Z Score","Tetrode","Cluster","Max_Overlap_Unit","accuracy"]));
    disp("All Appearences For unit")
    disp("appearence count:"+string(size(full_table,1)))
    [logical_grouping_results,tracked_faliures] = logical_grouping(full_table,config,true);
    disp("Grouping Results");


    par_save("faliures_"+unique_recording_list(i)+".mat",tracked_faliures);
    par_save("grouping_results_"+unique_recording_list(i)+".mat",logical_grouping_results);

end
end