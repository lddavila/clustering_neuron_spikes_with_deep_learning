function [output_table] = get_table_of_all_tetrodes_that_finished_blind_pass(config)
% this file serves to read all the results of
% run_entire_clustering_algorithm_ver_2.m

precomputed_dir = config.BLIND_PASS_DIR_PRECOMPUTED;
all_files_in_precomputed_dir = struct2table(dir(fullfile(precomputed_dir, '**', '*'))); % '**' searches subdirectories
simplified_foldernames = string(all_files_in_precomputed_dir{:,"folder"});
all_files_in_precomputed_dir = all_files_in_precomputed_dir(contains(simplified_foldernames,fullfile(precomputed_dir,"initial_pass_results min z_score")),:); 
all_files_in_precomputed_dir = all_files_in_precomputed_dir(~all_files_in_precomputed_dir{:,"isdir"},:);
only_files_with_output = all_files_in_precomputed_dir(contains(string(all_files_in_precomputed_dir{:,"name"}),"output"),:);
output_table = table(nan(size(only_files_with_output,1),1),repelem("",size(only_files_with_output,1),1),repelem("",size(only_files_with_output,1),1),repelem("",size(only_files_with_output,1),1),repelem("",size(only_files_with_output,1),1),repelem("",size(only_files_with_output,1),1),repelem("",size(only_files_with_output,1),1),repelem("",size(only_files_with_output,1),1),...
    'VariableNames', ...
    ["Z Score","Tetrode","fp_to_aligned","fp_to_output","fp_to_reg_timestamps_of_spikes","fp_to_reg_timestamps","fp_to_sorted_spike_windows_after_purges","fp_to_timestamps_rtvals"]);

unique_z_score_dirs = unique(string(only_files_with_output{:,"folder"}));
output_table_counter = 1;
for i=1:size(unique_z_score_dirs,1)
    current_z_score_dir = unique_z_score_dirs(i);
    z_score_dir_split = split(current_z_score_dir," ");
    current_z_score = str2double(z_score_dir_split{end});
    files_with_current_z_score = all_files_in_precomputed_dir(contains(string(all_files_in_precomputed_dir{:,"folder"}),current_z_score_dir,"IgnoreCase",true),:);
    all_mat_file_names_in_current_directory = files_with_current_z_score{:,"name"};
    split_mat_file_names = split(all_mat_file_names_in_current_directory," ");
    just_tetrodes = string(split_mat_file_names(:,1));
    unique_tetrodes = unique(just_tetrodes);

    for j=1:size(unique_tetrodes,1)
        output_table{output_table_counter,"Z Score"} = current_z_score;
        output_table{output_table_counter,"Tetrode"} = unique_tetrodes(j);
        list_of_files_for_current_tetrode = files_with_current_z_score(contains(string(all_mat_file_names_in_current_directory),unique_tetrodes(j)+" ","IgnoreCase",true),:);

        output_table{output_table_counter,"fp_to_aligned"} = fullfile(string(list_of_files_for_current_tetrode{1,"folder"}),unique_tetrodes(j)+" aligned.mat");
        output_table{output_table_counter,"fp_to_output"} = fullfile(string(list_of_files_for_current_tetrode{1,"folder"}),unique_tetrodes(j)+" output.mat");
        output_table{output_table_counter,"fp_to_reg_timestamps_of_the_spikes"} = fullfile(string(list_of_files_for_current_tetrode{1,"folder"}),unique_tetrodes(j)+" reg_timestamps_of_the_spikes.mat");
        output_table{output_table_counter,"fp_to_reg_timestamps"} = fullfile(string(list_of_files_for_current_tetrode{1,"folder"}),unique_tetrodes(j)+"reg_timestamps.mat");
        output_table{output_table_counter,"fp_to_sorted_spike_windows_after_purges"} = fullfile(string(list_of_files_for_current_tetrode{1,"folder"}),unique_tetrodes(j)+" sorted_spike_windows_after_purges.mat");
        output_table{output_table_counter,"fp_to_timestamps_rtvals"} = fullfile(precomputed_dir,"initial_pass min z_score"+string(current_z_score),unique_tetrodes(j)+".mat");
        
        output_table_counter = output_table_counter+1;
    end

end
end