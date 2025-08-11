function [blind_pass_table] = add_super_nn_prediction(blind_pass_table,config)
nn_struct = importdata(config.FP_TO_super_nn);
nn = nn_struct.net();
features_to_use = nn_struct.feature_names{1};
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
super_prediction = nan(size(sliced_bp_table,1),1);
for i=1:size(sliced_bp_table)
    currrent_data = sliced_bp_table{1};
    mean_wf = currrent_data{1,"mean_waveform_rep_wire_2"}{1};
    z_score = currrent_data{1,"Z Score"};
    grades = currrent_data{1,"grades"}{1};
    grades = cell2mat(grades(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST));
    nn_data = dlarray([grades,mean_wf,z_score]);
    class_pred = predict(nn,nn_data);
    [~,max_class_idx] = max(class_pred);
    super_prediction(i) = max_class_idx-1;
end
blind_pass_table.("super_pred") = super_prediction;
end