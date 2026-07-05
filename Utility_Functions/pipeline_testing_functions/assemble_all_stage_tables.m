function [final_stage_table] = assemble_all_stage_tables(dir_with_stage_tables,multiplier_or_z_score)
all_stage_tables = struct2table(dir(fullfile(dir_with_stage_tables, '**', '*.mat')));
all_stage_tables.name = string(all_stage_tables.name);
all_stage_tables.folder = string(all_stage_tables.folder);

split_folder = split(all_stage_tables.folder,filesep);
all_stage_tables.tetrode = split_folder(:,7);
stage_name = split(strrep(all_stage_tables{:,"name"},".mat",""),"_");
all_stage_tables.stage = str2double(stage_name(:,end));
all_stage_tables = sortrows(all_stage_tables,"stage","descend");
split_folder = split(all_stage_tables.folder,filesep);
if multiplier_or_z_score=="multiplier"
    all_stage_tables.multiplier = strrep(split_folder(:,end),"mult_","");
    grouped_table = slice_table_for_parallel_processing(all_stage_tables,["tetrode","multiplier"]);
else
    all_stage_tables.("Z Score") = strrep(split_folder(:,end),"mult_","");
    grouped_table = slice_table_for_parallel_processing(all_stage_tables,["tetrode","Z Score"]);
end
final_stage_table = [];
for i=1:height(grouped_table)
    current_group = grouped_table{i};
    % for j=1:height(current_group)
    current_table = load(fullfile(current_group{1,"folder"}, current_group{1,"name"}));
    current_table = current_table.data_to_save;

    %because of the way that the stage tables are assembled they may have
    %some repetitive information

    %to combat this we'll have to ensure only the unique values we care
    %about are stored

    %those unique values are unit and tetrode
    %any rows that have the same unit and tetrode are redundant and we'll
    %only take the first
    [~,unique_keys,~] = unique(current_table(:,["unit","tetrode"]),"rows","stable");
    current_table = current_table(unique_keys,:);

    % disp(size(current_table));
    %no table is guaranteed to hit the maximum stage allowed so we have to
    %include some logic to pad them when necessary
    
    current_vars = string(current_table.Properties.VariableNames);
    if i==1
        overall_list_of_vars = current_vars;
    end
    if ~isempty(setdiff(current_vars,overall_list_of_vars)) %the current table has variables the running table does not
        missing_vars = setdiff(current_vars,overall_list_of_vars);
        overall_list_of_vars = union(overall_list_of_vars,current_vars);
        for j=1:length(missing_vars) %pad the missing variables in the running table
            final_stage_table.(missing_vars(j)) = nan(height(final_stage_table),1);
        end
    end
    if ~isempty(setdiff(overall_list_of_vars,current_vars)) && i~=1 %the running table has variables the current table does not
        missing_vars = setdiff(overall_list_of_vars,current_vars);
        for j=1:length(missing_vars) %pad the current table with the vars is missing
            current_table.(missing_vars(j)) = nan(height(current_table),1);
        end
    end

    %reorganize the tables in case they were messed up by the padding so
    %concatenation won't fail
    % overall_list_of_vars(overall_list_of_vars=="") = [];
    if i~=1
        final_stage_table = final_stage_table(:,[overall_list_of_vars]);
        current_table = current_table(:,[overall_list_of_vars]);
    end
    final_stage_table = [final_stage_table;current_table];

    fprintf("Finished reading %i / %i\n",i,height(grouped_table));
end
end