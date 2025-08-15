function [row] = analyze_cluster_group_contamination(cell_array_of_grouped_clusters,config,ground_truth,curr_gr_lvl,curr_over_thresh,filtered_levels)
group_size = size(cell_array_of_grouped_clusters,2);
dominant_group_counts = zeros(1,size(ground_truth,2));
for i=1:size(cell_array_of_grouped_clusters,2)
    current_group = cell_array_of_grouped_clusters{i};
    under_unit_counts = groupcounts(current_group,"Max Overlap Unit");
    [max_count,index_of_max] = max(under_unit_counts{:,"Percent"});
    if max_count > 90 && size(current_group,1) ~=1
        dominant_group_counts(under_unit_counts{index_of_max,"Max Overlap Unit"}) = dominant_group_counts(under_unit_counts{index_of_max,"Max Overlap Unit"})+1; 
    end
end
number_of_units_with_dominant_group = sum(dominant_group_counts>0);
row = table(curr_gr_lvl,curr_over_thresh,number_of_units_with_dominant_group,filtered_levels,'VariableNames',["gr_lvl","predic_thre","num_units_with_dom_group","filtered_levels"]);
end