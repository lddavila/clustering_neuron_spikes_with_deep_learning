function [] = get_bar_plots_from_blind_pass_tables(blind_pass_table,list_of_gt_units,min_accuracy_for_found,simple_group)
number_of_found_units = 0;
for i=1:length(list_of_gt_units)
    c1 = blind_pass_table{:,"Max_Overlap_Unit"} ==list_of_gt_units(i);
    only_current_unit_examples = blind_pass_table(c1,:);
    if any(only_current_unit_examples.accuracy>min_accuracy_for_found)
        number_of_found_units = number_of_found_units+1;
    end
end
number_of_fabricated_clusters = length(simple_group);
for i=1:length(simple_group)
    current_group = simple_group{i};
    if any(current_group{:,"accuracy"}>min_accuracy_for_found)
        number_of_fabricated_clusters = number_of_fabricated_clusters-1;
    end
end
number_of_missing_units = length(list_of_gt_units) - number_of_found_units;
bar(["number of units found","number of missing units","number of fabricated clusters"],[number_of_found_units,number_of_missing_units,number_of_fabricated_clusters])
end