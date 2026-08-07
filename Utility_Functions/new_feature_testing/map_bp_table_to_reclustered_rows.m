function [] = map_bp_table_to_reclustered_rows(blind_pass_table,reclustered_table)

for i=1:height(blind_pass_table)
    current_ref_id = i;
    curr_rows = reclustered_table(reclusted_table{:,"ref_id"}==current_ref_id,:);
    max_overlap_unit = blind_pass_table{i,"Max_Overlap_Unit"};
    old_accuracy = blind_pass_table{i,"accuracy"};

    comparable_clusters = curr_rows{:,"Max_Overlap_Unit"}==max_overlap_unit;
    disp("The original row")
    disp(blind_pass_table(i,["Z Score","Tetrode","Cluster","Max_Overlap_Unit","accuracy","tp","fp","fn"]))

    disp("The new rows with same unit")
    disp(curr_rows(comparable_clusters,["Max_Overlap_unit","accuracy","tp","fp","fn"]));

    disp("Other clusters")
    disp(curr_rows(~comparable_clusters,["Max_Overlap_unit","accuracy","tp","fp","fn"]));
end
end