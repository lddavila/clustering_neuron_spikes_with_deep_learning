function [] = create_file_tree(fp_to_ft_table,dir_to_create_nested_file_tree)
home_dir = cd("..");
cd("..")
addpath(genpath(pwd));
cd(home_dir);
cd(dir_to_create_nested_file_tree);

all_entries = importdata(fp_to_ft_table);

%filter tree_table down to just the ones that have files we need
% Remove '.' and '..'
name_str = string(all_entries.name);
all_entries(name_str == "." | name_str == "..", :) = [];
disp("Finished filtering.");

% Keep only files
all_entries = all_entries(~all_entries.isdir, :);

% If you really want ALL files, don't filter by name:
files_to_transfer = all_entries(any(contains(string(all_entries.name),["aligned.mat","blind_pass_table.mat"]),2),:);

list_of_files_to_create = unique(string(files_to_transfer.folder));
for i=1:length(list_of_files_to_create)
    current_file_to_create = split(list_of_files_to_create(i),"/");
    place_where_default_starts = find(current_file_to_create=="Default_Results_Dir");
    create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(pwd,strjoin(current_file_to_create(place_where_default_starts+1:end),filesep)))
end
end