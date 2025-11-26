function [statistics_per_group] = analyze_grouped_clusters(cell_array_of_grouped_clusters,varargin)
group_names = nan(length(cell_array_of_grouped_clusters),1);
group_unit_composition = cell(length(cell_array_of_grouped_clusters),1);

majority_percentage = zeros(length(cell_array_of_grouped_clusters),1);
group_size = zeros(length(cell_array_of_grouped_clusters),1);
dominant_unit = zeros(length(cell_array_of_grouped_clusters),1);
for i=1:length(cell_array_of_grouped_clusters)
    current_group = cell_array_of_grouped_clusters{i};
    if any(ismember(current_group.Properties.VariableNames,"group_tags"))
        group_names(i) = current_group{1,"group_tags"}{1};
    else
        group_names(i) = i;
    end
    unit_counts_in_group = groupcounts(current_group,"Max_Overlap_Unit");
    group_unit_composition{i} = unit_counts_in_group;
    [majority_percentage(i),max_index] = max(unit_counts_in_group{:,"Percent"});
    group_size(i) = size(current_group,1);
    dominant_unit(i) = unit_counts_in_group{max_index,"Max_Overlap_Unit"};
end
statistics_per_group = table(group_names,dominant_unit,majority_percentage,group_size,group_unit_composition,...
    'VariableNames', ...
    ["Group Number","Dominant Unit","Max Percentage","# Members","Unit Breakdown"]);

%provided that non-empty ground truth array has been provided then we can get some additional statistics
ground_truth = varargin{1};
if isempty(ground_truth)
    return;
end
list_of_gt_units = 1:length(ground_truth);
missing_units = setdiff(list_of_gt_units,statistics_per_group{:,"Dominant Unit"});


end