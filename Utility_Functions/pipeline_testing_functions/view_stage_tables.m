function [] = view_stage_tables(stage_table,z_score_or_multiplier)
all_table_names = string(stage_table.Properties.VariableNames);
if z_score_or_multiplier == "z score"
    stage_table.("z score") = stage_table.all_multiplier_idxs;
    append_names = ["unit","tetrode","z score"];
else
    append_names = ["unit","tetrode","all_multiplier_idxs"];
end
raw_snr_names = all_table_names(contains(all_table_names,"raw_snr_"));
detection_names = all_table_names(contains(all_table_names,"detection_ratio_"));
grouped_table = slice_table_for_parallel_processing(stage_table,["tetrode","unit"]);

for i=1:length(grouped_table)
    current_table = grouped_table{i};
    disp("Signal to noise ratio at every stage");
    disp(current_table(:,[append_names,raw_snr_names]));
    disp("Ratio of unit spikes detected at every stage");
    disp(current_table(:,[append_names,detection_names]));
end
end