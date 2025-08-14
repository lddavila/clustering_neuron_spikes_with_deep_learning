function [results] = check_grouped_clusters_for_contamination(cluster_groups,number_of_units)
has_dominant_group = zeros(number_of_units,1);
for i=1:size(cluster_groups,2)
    current_data = cluster_groups{i};
    current_group_brkdwn = groupcounts(current_data,"Max Overlap Unit");
    disp(current_group_brkdwn);
    current_max_overlap_unit = current_group_brkdwn{1,"Max Overlap Unit"};
    if current_group_brkdwn{1,"Percent"} > 50
        has_dominant_group(current_max_overlap_unit) = has_dominant_group(current_max_overlap_unit)+1;
    end
end
results = table((1:number_of_units).',has_dominant_group,'VariableNames',["Unit","Has_Dominant_Group"]);
% disp(results);
missing_groups = setdiff(1:number_of_units,results{results{:,"Has_Dominant_Group"}>0,"Unit"});
disp("missing units")
disp(missing_groups)
end