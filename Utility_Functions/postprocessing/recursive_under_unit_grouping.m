function [surviving_groups] = recursive_under_unit_grouping(blind_pass_table,config)
ungrouped_clusters = blind_pass_table;
new_groups = determine_which_blind_pass_neurons_overlap(ungrouped_clusters,config);
disp("Finished Getting First Set Of Groups")
disp(size(new_groups));
surviving_groups = {}; 
while size(ungrouped_clusters,1) ~=0
    disp("Beginning ungrouping process")
    [new_groups,ungrouped_clusters] = check_cluster_groups_for_consistent_overlap(new_groups,config);
    disp("Finished ungrouping")
    disp("Number of ungrouped clusters:"+string(size(ungrouped_clusters,1)));
    for i=1:size(new_groups,2)
        surviving_groups{end+1} = new_groups{i};
    end

    new_groups = determine_which_blind_pass_neurons_overlap(ungrouped_clusters,config);
end

end