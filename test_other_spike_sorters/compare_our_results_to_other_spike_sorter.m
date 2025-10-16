function [table_of_stats] = compare_our_results_to_other_spike_sorter(blind_pass_table,other_spike_sorter_accuracy_dict,min_accuracy,num_gt_units)
comparisons = string(keys(other_spike_sorter_accuracy_dict));

table_of_stats = cell2table(cell(0,6),'VariableNames',["sorter","#_clusters_found","#_mua_clusters_created","#_missed_gt_units","missed_gt_units","repitition_table"]);
groupcounts_of_bp = groupcounts(blind_pass_table,"Max_Overlap_Unit");



list_of_gt_units = 1:num_gt_units;
missing_gt_units = list_of_gt_units;
gt_unit_repitions = zeros(length(list_of_gt_units),1);
for i=1:length(list_of_gt_units)
    only_for_current = blind_pass_table(blind_pass_table{:,"Max_Overlap_Unit"}==i,:);

    gt_unit_repitions(i) = size(only_for_current,1);
    if ~any(only_for_current{:,"accuracy"}>=min_accuracy,"all")
    else
        missing_gt_units(missing_gt_units==i)= [];
    end
end

repitition_table = table(list_of_gt_units.',gt_unit_repitions);


current_row = table("ours",size(blind_pass_table,1),sum(blind_pass_table{:,"accuracy"}<min_accuracy),length(missing_gt_units),{missing_gt_units},{repitition_table}, ...
    'VariableNames', ...
    ["sorter","#_clusters_found","#_mua_clusters_created","#_missed_gt_units","missed_gt_units","repitition_table"]);
table_of_stats = [table_of_stats;current_row];
for k=1:length(comparisons)
    current_other_spike_sorter = comparisons(k);
    spike_sorter = split(current_other_spike_sorter," ");

    other_table_agreement_matrix = other_spike_sorter_accuracy_dict(current_other_spike_sorter);
    list_of_gt_units_missed = find(all(other_table_agreement_matrix{:,:}<min_accuracy,1));
    gt_unit_repitions = zeros(length(list_of_gt_units),1);
    for i=1:length(list_of_gt_units)
        gt_unit_repitions(i) = sum(other_table_agreement_matrix{:,i}>min_accuracy,"all");
    end
    repitition_table = table(list_of_gt_units.',gt_unit_repitions);
    current_row = table(string(spike_sorter{end}),size(other_table_agreement_matrix,1), ...
        sum(all(other_table_agreement_matrix{:,:}<min_accuracy,2)), ...
        length(list_of_gt_units_missed),{list_of_gt_units_missed},{repitition_table},...
        'VariableNames', ...
        ["sorter","#_clusters_found","#_mua_clusters_created","#_missed_gt_units","missed_gt_units","repitition_table"]);
    table_of_stats = [table_of_stats;current_row];

    %we must get the following stats for each sorter including ours
    %The number of clusters found

    %the number of repititons per ground truth unit
    %how many MUA clusters were created through the process

end
end