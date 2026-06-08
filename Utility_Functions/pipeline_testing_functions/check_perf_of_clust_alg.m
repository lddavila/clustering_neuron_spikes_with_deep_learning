function [] = check_perf_of_clust_alg(min_detection_rate,blind_pass_table,config)
list_of_units_per_rec = 1:1:600;
unique_recordings = unique(blind_pass_table{:,"recording_name"});
det_perc = zeros(1,length(unique_recordings));
for i=1:length(unique_recordings)
    c1 = blind_pass_table{:,"recording_name"}==unique_recordings(i);
    current_rows = blind_pass_table(c1,:);
    found_units = unique(current_rows{current_rows{:,"accuracy"}>min_detection_rate,"Max_Overlap_Unit"});
    det_perc(i) = length(found_units) / length(list_of_units_per_rec);
end
disp(det_perc);
disp("Mean det percentage")
disp(mean(det_perc,"all"));
end