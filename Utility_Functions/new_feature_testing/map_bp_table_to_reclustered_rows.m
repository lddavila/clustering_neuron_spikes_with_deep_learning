function [] = map_bp_table_to_reclustered_rows(blind_pass_table,reclustered_table)
increase_tracker = [];
all_found_units = unique(blind_pass_table.("Max_Overlap_Unit"));
new_units = [];
for i=1:height(blind_pass_table)
    current_ref_id = i;
    curr_rows = reclustered_table(reclustered_table{:,"ref_id"}==current_ref_id,:);
    max_overlap_unit = blind_pass_table{i,"Max_Overlap_Unit"};
    old_accuracy = blind_pass_table{i,"accuracy"};

    comparable_clusters = curr_rows{:,"Max_Overlap_Unit"}==max_overlap_unit;
    disp("The original row")
    disp(blind_pass_table(i,["Z Score","Tetrode","Cluster","Max_Overlap_Unit","accuracy","tp","fp","fn","channels"]))

    disp("The new rows with same unit")
    com_clust = sortrows(curr_rows(comparable_clusters,:),"accuracy","descend");
    disp(sortrows(com_clust(:,["Max_Overlap_Unit","accuracy","tp","fp","fn","channels"]),"accuracy","descend"));
    if ~isempty(com_clust)
        increase_tracker = [increase_tracker;com_clust(1,"accuracy") - old_accuracy];
    end
    % for j=1:height(com_clust)
    %
    % end

    % disp("Other clusters")
    % disp(curr_rows(~comparable_clusters,["Max_Overlap_Unit","accuracy","tp","fp","fn"]));
    
    new_units = [new_units;unique(curr_rows{~comparable_clusters,"Max_Overlap_Unit"})];
    clc;
end

disp("Average increase:")
disp(mean(increase_tracker))

units_not_found = setdiff(new_units,all_found_units);
disp("Units found in reclustering that were not found in intital clustering")
disp(units_not_found);

disp("number of new units found")
disp(length(units_not_found));

avg_for_new_units = [];
for i=1:length(units_not_found)
    c1 = reclustered_table{:,"Max_Overlap_Unit"} == units_not_found(i);
    avg_for_new_units = [avg_for_new_units;mean(reclustered_table{c1,"accuracy"})];
end
disp("average accuracy for the new found units")
disp([units_not_found,avg_for_new_units]);

disp("average of the average");
disp(mean(avg_for_new_units));

avg_for_new_units = [];
for i=1:length(all_found_units)
    c1 = blind_pass_table{:,"Max_Overlap_Unit"} == all_found_units(i);
    avg_for_new_units = [avg_for_new_units;mean(blind_pass_table{c1,"accuracy"})];
end
disp("average accuracy for the new found units");
disp([all_found_units,avg_for_new_units]);

end