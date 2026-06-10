function [] = get_grade_correlation_with_accuracy_plots(config,transformed_or_not,blind_pass_table,randomly_sample,varargin)
%config: struct 
    %a struct that can be created via the following call: config = spikesort_config;
%transformed_or_not: boolean
    %0: do not rescale the data
    %1: rescale the data
%blind_pass_table: table
    %a table object created by the pipeline
    %requires the grades col 
%varargin:cell array
    %if not empty then it should be an array of grade indexes 
    % only the specified indexes will have their correlation plots created  

%this function will plot correlation between our grades and accuracy on an
%x-y plot with the x axis representing the grade bound
%and the y axis showing accuracy
%we'll alow the caller to specify whether or not to rescale the data as we
%do when training the neural networks

%filter out MUA clusters since they will torch results
%here we'll define MUA as any cluster with less than 10% accuracy
% blind_pass_table(blind_pass_table{:,"accuracy"}<10,:) = [];




%randomly sample if specified
%done because the data is so dense it appears as just a cloud 
% rng(0);
% randomly_chosen_rows = randperm(height(blind_pass_table),1000);
% blind_pass_table = blind_pass_table(randomly_chosen_rows,:);

%create a file to save the plots to
file_to_save_plain_plots_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"untransformed_grade_plots"));



%get the grades
list_of_features_to_add = ["grades 3"];
grades_array = cell2mat(assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config));
true_accuracy = blind_pass_table{:,"accuracy"};

%remove any rows that have inf 
true_accuracy(any(isinf(grades_array),2),:) = [];
grades_array(any(isinf(grades_array),2),:) = [];

%get bins based off accuracy
accuracy_bins = discretize(true_accuracy,0:1:ceil(max(true_accuracy)));

%get transformed data
table_of_nets = struct2table(dir(fullfile(config.dir_of_prob_dist_nets,"*.mat")));
net_names = string(table_of_nets.name);
split_net_names = split(net_names,"_");
[~,where_below_ends ]= find(split_net_names=="below");
net_nums = arrayfun(@(i) split_net_names(i, where_below_ends(i)+1), ...
    (1:size(split_net_names,1))');
table_of_nets.threshold = str2double(net_nums);
table_of_nets = sortrows(table_of_nets,"threshold","ascend");
cell_array_of_transformed_data = cell(height(table_of_nets),1);
if transformed_or_not
    for i=1:height(table_of_nets)
        current_net_path = fullfile(table_of_nets{i,"folder"}{1},table_of_nets{i,"name"}{1});
        current_net = importdata(current_net_path);
        input_max = current_net.InputMax;
        input_min = current_net.InputMin;
        cell_array_of_transformed_data{i} = rescale(grades_array,0,1,"InputMax",input_max(1:size(grades_array,2)),"InputMin",input_min(1:size(grades_array,2)));

    end
end

%for every grade plot the grade along the x-axis
%plot the accuracy along the y-axis
unique_accuracy_bins = unique(accuracy_bins);
for i=1:size(grades_array,2)
    f = figure;
    percentile_grade_vals = zeros(1,length(unique_accuracy_bins));
    spread_of_grade_vals = zeros(1,length(unique_accuracy_bins));
    for j=1:length(unique_accuracy_bins)
        [spread_of_grade_vals(j),percentile_grade_vals(j)] = std(grades_array(accuracy_bins==unique_accuracy_bins(j),i),"omitmissing");
    end
    [R,P] = corrcoef(true_accuracy,grades_array(:,i));
    errorbar(unique_accuracy_bins,percentile_grade_vals,spread_of_grade_vals,"-s","MarkerSize",10,...
    "MarkerEdgeColor","blue","MarkerFaceColor",[0.65 0.85 0.90]);
    ylabel("Grade "+string(i))
    xlabel("Accuracy")
    title("Grade "+string(i))
    subtitle("R:"+string(R(1,2))+" P:"+string(P(1,2)))
    saveas(f,fullfile(file_to_save_plain_plots_to,"Grade_"+string(i)+".png"))
    saveas(f,fullfile(file_to_save_plain_plots_to,"Grade_"+string(i)+".svg"))
    saveas(f,fullfile(file_to_save_plain_plots_to,"Grade_"+string(i)+".fig"))
    close(f);
    if transformed_or_not
        %create a file to save transformed plots to
        file_to_save_transformed_plots_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"transformed_grade_plots"));
        figure;
        legend_string = repelem("",length(cell_array_of_transformed_data));
        for j=1:length(cell_array_of_transformed_data)
            current_transformed_grades = cell_array_of_transformed_data{j}(:,i);
            trans_percentile_grade_vals = zeros(1,length(unique_accuracy_bins));
            tran_spread_of_grade_vals = zeros(1,length(unique_accuracy_bins));
            for k=1:length(unique_accuracy_bins)
                [tran_spread_of_grade_vals(j),trans_percentile_grade_vals(j)] = std(current_transformed_grades(accuracy_bins==k),"omitmissing");
            end
            % [R_trans,P_trans] = corrcoef(true_accuracy,cell_array_of_transformed_data{j}(:,i));
            errorbar(unique_accuracy_bins,trans_percentile_grade_vals,tran_spread_of_grade_vals,"-s","MarkerSize",10,...
    "MarkerEdgeColor","blue","MarkerFaceColor",[0.65 0.85 0.90]);
            legend_string(j) = "Grade: "+string(i)+" Scaled for Threshold: "+string(j);
            hold on;
        end
        legend(legend_string);
        title("Transformed at Every Threshold")
        ylabel("Accuracy");
        xlabel("Rescaled Grade: "+string(i))
    end
    % close all;
end


end