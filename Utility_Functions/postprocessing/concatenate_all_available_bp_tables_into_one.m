function [] = concatenate_all_available_bp_tables_into_one()
[dir,~,~] = fileparts(mfilename('fullpath'));
cd(dir);
home_dir = cd("..");
cd("..");
addpath(genpath(pwd))
cd(home_dir)
disp("Finished adding path");

config = spikesort_config();
disp("Finished getting config");

dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path( ...
    fullfile(config.parent_save_dir,"master_bp_table"));

%get all .mat files in default results directory
table_of_all_blind_pass_tables = struct2table(dir(fullfile(config.base_file_path,"Default_Results_Dir","*/**.mat")));

%filter down to only the blind_pass_tables 
table_of_all_blind_pass_tables = table_of_all_blind_pass_tables(string(table_of_all_blind_pass_tables{:,"name"})=="blind_pass_table.mat");

%concatenate all blind pass tables into a single one
single_bp_table = cell(height(table_of_all_blind_pass_tables),1);
for i=1:height(table_of_all_blind_pass_tables)
    current_dir = string(table_of_all_blind_pass_tables{i});
    current_bp_table = importdata(fullfile(current_dir,"blind_pass_table.mat"));
    
end
single_bp_table = vertcat(single_bp_table(:));
par_save(fullfile(dir_to_save_results_to,"all_channel_perms_bp_table.mat"),single_bp_table);

end