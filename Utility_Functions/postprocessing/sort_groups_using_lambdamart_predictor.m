function [sorted_groups] = sort_groups_using_lambdamart_predictor(groups,config)
fp_to_lambda_mart_model = config.fp_to_lambdaMART_predictor;
list_of_features_to_add = ["grades 2","valley_1","valley_2"];
sorted_groups = cell(length(groups));
for i=1:length(groups)
    data_to_export = assemble_data_for_neural_net(list_of_features_to_add,groups{i},config);
    data_to_export = cell2mat(data_to_export);
    sorted_positions = pyrunfile(fullfile(config.base_file_path,"Utility_Functions","postprocessing","sort_groups_using_lambdamart_model.py"),fp_to_lambda_mart_model,data_to_export);
    sorted_groups{i} = groups{i}(sorted_positions,:);
end
end