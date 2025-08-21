function [blind_pass_table] = add_multi_under_unit_pred_col(blind_pass_table,config)
nn_struct = importdata(config.FP_TO_Multi_under_units_predicting_nn);
nn = nn_struct.net;
has_multi_under_units = nan(size(blind_pass_table,1),1);
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
for i=1:size(sliced_bp_table,1)
    current_data = sliced_bp_table{i};
    mean_waveform = current_data{:,"mean_waveform_rep_wire_1"}{1};
    grades = vertcat(current_data{:,"grades"}{1});
    grades = vertcat(grades{config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST}).';
    has_multi_under_units_probabilities = predict(nn,[grades,mean_waveform]);
    [~,class_index] = max(has_multi_under_units_probabilities);
    has_multi_under_units(i) = class_index-1;
end
blind_pass_table.("has_multi_under_units") = has_multi_under_units;
end