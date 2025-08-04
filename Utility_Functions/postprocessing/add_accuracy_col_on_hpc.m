function [table_of_clusters] = add_accuracy_col_on_hpc(ts_array,config,table_of_clusters,number_of_categories)
disp("Starting To Add Accuracy Category")
% accuracy_array = nan(size(table_of_clusters,1),1);
% ground_truth = importdata(config.FP_TO_GT_FOR_RECORDING_ON_HPC);
% timestamps = importdata(config.TIMESTAMP_FP_ON_HPC);

accuracy_category = nan(size(table_of_clusters,1),1);
% sliced_ground_truth_ts = cell(size(table_of_clusters,1));
sliced_table = cell(size(table_of_clusters,1),1);

categories = linspace(1,100,number_of_categories);

for i=1:size(table_of_clusters,1)
    % sliced_ground_truth_ts{i} = timestamps(ground_truth{table_of_clusters{i,"Max Overlap Unit"}});
    sliced_table{i} = table_of_clusters(i,:);
end


parfor i=1:size(table_of_clusters,1)
    % gt_ts = sliced_ground_truth_ts{i};
    % cluster_spike_ts = ts_array{i};
    % accuracy_array(i) = calculate_accuracy(gt_ts,{cluster_spike_ts},config) * 100;
    current_data = sliced_table{i};
    current_accuracy_score = current_data{1,"accuracy"};
    for j=1:size(categories,2)
        if current_accuracy_score < categories(j)
            accuracy_category(i) = j-1;
            break;
        end
    end
    % disp("add_accuracy_col Finished "+string(i)+"/"+string(size(table_of_clusters,1)));
end
disp("Finished Adding Accuracy Category")
% table_of_clusters.accuracy = accuracy_array;
table_of_clusters.accuracy_category = accuracy_category;

end