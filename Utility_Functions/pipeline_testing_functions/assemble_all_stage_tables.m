function [final_stage_table] = assemble_all_stage_tables(dir_with_stage_tables,multiplier_or_z_score)
all_stage_tables = struct2table(dir(fullfile(dir_with_stage_tables, '**', '*.mat')));
all_stage_tables.name = string(all_stage_tables.name);
all_stage_tables.folder = string(all_stage_tables.folder);

split_folder = split(all_stage_tables.folder,filesep);
all_stage_tables.tetrode = split_folder(:,8);

if multiplier_or_z_score=="multiplier"
    all_stage_tables.multiplier = strrep(split_folder(:,9),"mult_","");
    grouped_table = slice_table_for_parallel_processing(all_stage_tables,["tetrode","multiplier"]);
else
    all_stage_tables.("Z Score") = strrep(split_folder(:,9),"mult_","");
    grouped_table = slice_table_for_parallel_processing(all_stage_tables,["tetrode","Z Score"]);
end
final_stage_table = [];
parfor i=1:height(all_stage_tables)
    current_group = grouped_table{i};
    % for j=1:height(current_group)
    current_table = importdata(fullfile(current_group{1,"folder"}, current_group{1,"name"}));
    disp(size(current_table));
    final_stage_table = [final_stage_table;current_table];
    % end
end
end