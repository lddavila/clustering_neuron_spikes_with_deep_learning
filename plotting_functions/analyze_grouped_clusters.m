function [statistics_per_group,is_in_table] = analyze_grouped_clusters(cell_array_of_grouped_clusters,ground_truth_cell_array)

group_names = string(1:size(cell_array_of_grouped_clusters,2)).';
group_unit_composition = cell(size(cell_array_of_grouped_clusters,2),1);
is_made_up_of_single = zeros(size(cell_array_of_grouped_clusters,2),1);
majority_percentage = zeros(size(cell_array_of_grouped_clusters,2),1);
group_size = zeros(size(cell_array_of_grouped_clusters,2),1);
dominant_unit = zeros(size(cell_array_of_grouped_clusters,2),1);
for i=1:size(cell_array_of_grouped_clusters,2)
    current_group = cell_array_of_grouped_clusters{i};
    unit_counts_in_group = groupcounts(current_group,"Max Overlap Unit");
    group_unit_composition{i} = unit_counts_in_group;
    if size(unit_counts_in_group,1) == 1
        is_made_up_of_single(i) = 1;
    end
    [majority_percentage(i),max_index] = max(unit_counts_in_group{:,"Percent"});
    group_size(i) = size(current_group,1);
    dominant_unit(i) = unit_counts_in_group{max_index,"Max Overlap Unit"};
end
statistics_per_group = table(group_names,dominant_unit,majority_percentage,group_size,group_unit_composition,is_made_up_of_single,...
    'VariableNames', ...
    ["Group Number","Dominant Unit","Max Percentage","# Members","Unit Breakdown","All Same Unit"]);

ground_truth_units_list = 1:size(ground_truth_cell_array,2);
is_in_matrix = nan(1,size(ground_truth_units_list,2));
for i=ground_truth_units_list
    if ismember(i,statistics_per_group{:,"Dominant Unit"})
        is_in_matrix(i) = 1;
    end
end

is_in_table = array2table(is_in_matrix,'VariableNames',strcat("Unit ",string(ground_truth_units_list)).');

end