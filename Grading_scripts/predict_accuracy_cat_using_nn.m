function [accuracy_cat] = predict_accuracy_cat_using_nn(config,mean_waveform)
accuracy_cat = 0;
if isempty(mean_waveform)
    return
end
if config.ON_HPC
    nn_struct = importdata(config.FP_TO_PREDICT_ACC_CAT_USING_MEAN_WAVEFORM_NN_ON_HPC);
else
    nn_struct = importdata(config.FP_TO_PREDICT_ACC_CAT_USING_MEAN_WAVEFORM_NN);
end
acc_cat_nn =nn_struct.net;
class_prediction_probabilities = predict(acc_cat_nn,mean_waveform);
[~,max_prob_ind] = max(class_prediction_probabilities);

accuracy_cat = max_prob_ind-1;
end