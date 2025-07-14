function [] = add_accuracy_cat_pred_from_nn(blind_pass_table,config)
acc_pred_nn_struct = importdata(config.FP_TO_GRADES_ACC_PRED_WITH_RANK_NN);
acc_pred_nn = acc_pred_nn_struct.net;
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
for i=1:size(sliced_bp_table,1)
end
end