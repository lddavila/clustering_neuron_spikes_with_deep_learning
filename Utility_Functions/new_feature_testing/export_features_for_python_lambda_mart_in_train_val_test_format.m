function [] = export_features_for_python_lambda_mart_in_train_val_test_format(blind_pass_table,config)


%remove any examples for very low accuracy
blind_pass_table(blind_pass_table{:,"accuracy"}<1,:)=[];
% --- Features ---
list_of_features_to_add = ["grades 2","valley_1","valley_2"];
training_recordings = ["10_600Neuron300SecondRecordingWithLevel10Noise","9_600Neuron300SecondRecordingWithLevel9Noise","8_600Neuron300SecondRecordingWithLevel8Noise","7_600Neuron300SecondRecordingWithLevel7Noise"];
val_recordings = ["4_600Neuron300SecondRecordingWithLevel4Noise","3_600Neuron300SecondRecordingWithLevel3Noise","2_600Neuron300SecondRecordingWithLevel2Noise","`_600Neuron300SecondRecordingWithLevel1Noise"];

test_recordings = ["6_600Neuron300SecondRecordingWithLevel6Noise"];


%select recording 6 this will be the training data
training_data = blind_pass_table(any(blind_pass_table{:,"recording_name"}==training_recordings,2),:);

%select recording 7 this will be the validation data
val_data = blind_pass_table(any(blind_pass_table{:,"recording_name"}==val_recordings,2),:);

%select recording 6 this will be used for testing data
test_data = blind_pass_table(blind_pass_table{:,"recording_name"}==test_recordings,:);

training_data_to_export = assemble_data_for_neural_net(list_of_features_to_add,training_data,config);
training_data_to_export = cell2mat(training_data_to_export);

col_min = min(training_data_to_export,[],1);
col_max = max(training_data_to_export,[],1);

% training_data_to_export = rescale(training_data_to_export,0,100,"InputMax",col_max,"InputMin",col_min);

training_data_to_export = array2table(training_data_to_export,"VariableNames",[config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST),"1st_valley_1","1st_valley_2","1st_valley_3","1st_valley_4","2nd_valley_1","2nd_valley_2","2nd_valley_3","2nd_valley_4"]);
training_data_to_export.("z_score") = training_data.("Z Score");
training_data_to_export.("tetrode") = training_data.("Tetrode");
training_data_to_export.("cluster") = training_data.("Cluster");
training_data_to_export.("accuracy") = training_data.("accuracy");
training_data_to_export.("recording") = training_data.("recording_name");

val_data_to_export = assemble_data_for_neural_net(list_of_features_to_add,val_data,config);
val_data_to_export = cell2mat(val_data_to_export);
% val_data_to_export = rescale(val_data_to_export,0,100,"InputMax",col_max,"InputMin",col_min);
val_data_to_export = array2table(val_data_to_export,"VariableNames",[config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST),"1st_valley_1","1st_valley_2","1st_valley_3","1st_valley_4","2nd_valley_1","2nd_valley_2","2nd_valley_3","2nd_valley_4"]);
val_data_to_export.("z_score") = val_data.("Z Score");
val_data_to_export.("tetrode") = val_data.("Tetrode");
val_data_to_export.("cluster") = val_data.("Cluster");
val_data_to_export.("accuracy") = val_data.("accuracy");
val_data_to_export.("recording") = val_data.("recording_name");


test_data_to_export = assemble_data_for_neural_net(list_of_features_to_add,test_data,config);
test_data_to_export = cell2mat(test_data_to_export);
% test_data_to_export = rescale(test_data_to_export,0,100,"InputMax",col_max,"InputMin",col_min);
test_data_to_export = array2table(test_data_to_export,"VariableNames",[config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST),"1st_valley_1","1st_valley_2","1st_valley_3","1st_valley_4","2nd_valley_1","2nd_valley_2","2nd_valley_3","2nd_valley_4"]);
test_data_to_export.("z_score") = test_data.("Z Score");
test_data_to_export.("tetrode") = test_data.("Tetrode");
test_data_to_export.("cluster") = test_data.("Cluster");
test_data_to_export.("accuracy") = test_data.("accuracy");
test_data_to_export.("recording") = test_data.("recording_name");



writetable(training_data_to_export,fullfile(config.parent_save_dir,"lambda_mart_training_features_normalized.csv"))
writetable(val_data_to_export,fullfile(config.parent_save_dir,"lambda_mart_val_features_normalized.csv"))
writetable(test_data_to_export,fullfile(config.parent_save_dir,"lambda_mart_test_features_normalized.csv"))
end