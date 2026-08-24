function [full_table] = concatenate_all_bp_tables_with_new_features(dir_with_blind_pass_tables)
all_files = struct2table(dir(fullfile(dir_with_blind_pass_tables,'**/*blind_pass_table.mat')));
all_files.folder = string(all_files.folder);
all_files.name = string(all_files.name);

all_files(contains(all_files.folder,"blind_pass_table","IgnoreCase",true),:) = [];

full_table = [];
for i=1:height(all_files)
    curr_table = importdata(fullfile(all_files{i,"folder"},all_files{i,"name"}));
    curr_path_split = split(all_files.folder,filesep);
    curr_features = curr_path_split(i,end);
    curr_table.new_features = repelem(curr_features,height(curr_table),1);
    full_table = [full_table;curr_table];
end
end