function [recombined_groups] = check_if_any_cluster_groups_can_be_combined(cell_array_of_cluster_groups,config)

%get the highest percentile example within each group
best_per_group = [];
for i =1:size(cell_array_of_cluster_groups,2)
    disp(i)
    current_data = cell_array_of_cluster_groups{i}; 
    current_data.original_group = zeros(size(current_data,1),1)+1;
    if size(current_data,1) ~=1
        current_data = sortrows(current_data,"Percentile");
        best_example = current_data(end,:);
    else
        best_example = current_data(1,:);
        best_example.Percentile = 1;
    end
    best_per_group = [best_per_group;best_example];
end

%now use the choose better neural network to see if the best clusters per group are useful 
list_of_features_to_add = ["grades"];
grades = assemble_data_for_neural_net(list_of_features_to_add,best_per_group,config);
grades = grades{1};

new_groups = determine_which_blind_pass_neurons_overlap_parallel(best_per_group,config);
recombined_groups = cell(1,size(new_groups,2));
for i=1:(size(new_groups,2))
    current_recombined_group = new_groups{i};
    original_groups = current_recombined_group{:,"original_group"};
    recombined_groups{i} = vertcat(cell_array_of_cluster_groups{original_groups});
end
end