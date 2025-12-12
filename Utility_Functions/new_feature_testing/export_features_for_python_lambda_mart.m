function [] = export_features_for_python_lambda_mart(blind_pass_table,config)


%remove any examples for very low accuracy
blind_pass_table(blind_pass_table{:,"accuracy"}<1,:)=[];
% --- Features ---
list_of_features_to_add = ["grades 2","valley_1","valley_2"];

data_to_export = assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config);
data_to_export = cell2mat(data_to_export);
data_to_export = array2table(data_to_export,"VariableNames",[config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST),"1st_valley_1","1st_valley_2","1st_valley_3","1st_valley_4","2nd_valley_1","2nd_valley_2","2nd_valley_3","2nd_valley_4"]);
data_to_export.("z_score") = blind_pass_table.("Z Score");
data_to_export.("tetrode") = blind_pass_table.("Tetrode");
data_to_export.("cluster") = blind_pass_table.("Cluster");
data_to_export.("accuracy") = blind_pass_table.("accuracy");
data_to_export.("recording") = blind_pass_table.("recording_name");

writetable(data_to_export,fullfile(config.parent_save_dir,"lambda_mart_features.csv"))
end