function [recombined_groups] = check_if_any_cluster_groups_can_be_combined(cell_array_of_cluster_groups,config)
recombined_groups = [];
%get the highest percentile example within each group
best_per_group = [];
original_group = [];
for i =1:size(cell_array_of_cluster_groups,2)
    disp(i)
    current_data = cell_array_of_cluster_groups{i}; 
    current_data = sortrows(current_data,"Percentile");
    best_example = current_data(end,:);
    best_per_group = [best_per_group;best_example];
    original_group = [original_group;i];
end

%now use the choose better neural network to see if the best clusters per group are useful 
list_of_features_to_add = ["grades"];
grades = assemble_data_for_neural_net(list_of_features_to_add,best_per_group,config);
end