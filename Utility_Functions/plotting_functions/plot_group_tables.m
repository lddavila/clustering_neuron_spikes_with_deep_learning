
for i=1:length(recording_6_groups)
    disp("+++++++++++++++++++++++++++++++++++++++++++++++")
    current_data = recording_6_groups{i};
    disp(current_data(:,["Z Score","Tetrode","Cluster","Max_Overlap_Unit","accuracy"]))
    disp("++++++++++++++++++++++++++++++++++++++++++++++++++");
end