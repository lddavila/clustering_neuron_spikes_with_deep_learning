function [analysis_table] = analyze_cluster_table(blind_pass_table,ground_truth)
unit_list = 1:size(ground_truth,2);
analysis_table = table(nan(size(unit_list,2)),nan(size(unit_list,2)),nan(size(unit_list,2)),nan(size(unit_list,2)),nan(size(unit_list,2)),'VariableNames', ...
    ["Unit","# of Appearences","Average Accuracy","Min Accuracy","Max Accuracy"]);
analysis_table.Unit = unit_list.';
average_accuracy = zeros(size(unit_list,2),1);
number_of_appearences = zeros(size(unit_list,2),1);
min_accuracy_for_unit = zeros(size(unit_list,2),1);
max_accuracy_for_unit = zeros(size(unit_list,2),1);
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,["Max Overlap Unit"]);

for i=1:size(sliced_bp_table,1)
    current_data = sliced_bp_table{i};
    unit_id = current_data{1,"Max Overlap Unit"};
    accuracy_data = current_data{:, "accuracy"};
    number_of_appearences(unit_id) = size(current_data,1);
    average_accuracy(unit_id) = mean(accuracy_data, 'omitnan');
    min_accuracy_for_unit(unit_id) = min(accuracy_data, [], 'omitnan');
    max_accuracy_for_unit(unit_id) = max(accuracy_data, [], 'omitnan');
end
analysis_table.("Average Accuracy") = average_accuracy;
analysis_table.("# of Appearences") = number_of_appearences;
analysis_table.("Min Accuracy") = min_accuracy_for_unit;
analysis_table.("Max Accuracy") = max_accuracy_for_unit;
end