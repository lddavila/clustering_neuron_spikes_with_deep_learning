function [blind_pass_table] = add_mean_waveform_pred_col(blind_pass_table,config)
mean_waveform_pred_struct = importdata(config.FP_TO_PREDICT_ACC_CAT_USING_MEAN_WAVEFORM_NN);
mean_wave_pred_nn = mean_waveform_pred_struct.net;
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
acc_cat_prediction = nan(size(blind_pass_table,1),1);
num_iterations = size(sliced_bp_table,1);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
print_status_bar(num_iterations,"add_mean_wf_prediction_col.m")

parfor i=1:size(sliced_bp_table,1)
    current_data = sliced_bp_table{i};
    current_mean_waverform = current_data{1,"mean_waveform_rep_wire_1"}{1};
    acc_cat_probs = predict(mean_wave_pred_nn,current_mean_waverform);
    [~,max_prob_idx] = max(acc_cat_probs);
    acc_cat_prediction(i) = max_prob_idx-1;
    send(q,[]);
end
blind_pass_table.("mean_wave_pred") = acc_cat_prediction;
end