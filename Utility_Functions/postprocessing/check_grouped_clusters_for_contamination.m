function [results] = check_grouped_clusters_for_contamination(cluster_groups,number_of_units)
clc;
has_dominant_group = zeros(number_of_units,1);
cell_array_of_groupcounts = cell(size(cluster_groups,2),1);
for i=1:size(cluster_groups,2)
    current_data = cluster_groups{i};
    current_group_brkdwn = groupcounts(current_data,"Max Overlap Unit");
    current_group_brkdwn = sortrows(current_group_brkdwn,"GroupCount","ascend");
    % disp(current_group_brkdwn);
    current_max_overlap_unit = current_group_brkdwn{end,"Max Overlap Unit"};
    if current_group_brkdwn{end,"Percent"} > 50
        has_dominant_group(current_max_overlap_unit) = has_dominant_group(current_max_overlap_unit)+1;
    end
    cell_array_of_groupcounts{i} = current_group_brkdwn;

end
results = table((1:number_of_units).',has_dominant_group,'VariableNames',["Unit","Has_Dominant_Group"]);
% disp(results);
missing_groups = setdiff(1:number_of_units,results{results{:,"Has_Dominant_Group"}>0,"Unit"});
disp("missing units")
disp(missing_groups)

if isempty(missing_groups)
    return
end

for i=1:size(missing_groups,2)
    current_missing_unit = missing_groups(i);
    disp("Missing Unit"+string(current_missing_unit)+" Appears in the following groups:")
    for j=1:size(cell_array_of_groupcounts,1)
        current_group_brkdwn = cell_array_of_groupcounts{j};
        if any(current_group_brkdwn{:,"Max Overlap Unit"}==current_missing_unit)
            disp(current_group_brkdwn)
        end
    end
    disp("###################################################")
end
end