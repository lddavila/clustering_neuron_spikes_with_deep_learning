function [sorted_groups] = sort_groups_using_lambdamart_predictor(groups,config)
fp_to_lambda_mart_model = config.fp_to_lambdaMART_predictor;
list_of_features_to_add = ["grades 2","valley_1","valley_2"];
sorted_groups = cell(length(groups),1);
for i=1:length(groups)
    data_to_export = assemble_data_for_neural_net(list_of_features_to_add,groups{i},config);
    data_to_export = cell2mat(data_to_export);

    pyFile = fullfile(config.base_file_path,"Utility_Functions","postprocessing","sort_groups_using_lambdamart_model.py");
    out = pyrunfile(pyFile, "sorted_positions", ...
    grades_of_cluster_groups=data_to_export, ...
    fp_to_lambdamart_model=fp_to_lambda_mart_model);

sorted_positions = double(out.');
% if needed: sorted_positions = sorted_positions + 1;
sorted_groups{i} = groups{i}(sorted_positions,:);
end

%create a plot
for i=1:length(sorted_groups)
    figure;
    tiledlayout(1,2);
    
    nexttile()
    bar(groups{i}{:,"accuracy"});
    xlabel("position")
    ylabel("Accuracy")
    title("Before Sorting")
    ylim([0,100])

    nexttile()
    bar(sorted_groups{i}{:,"accuracy"});
    xlabel("position")
    ylabel("Accuracy")
    title("After Sorting")
    ylim([0,100])
    close(gcf);
end
end