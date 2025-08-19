function [assembled_data] = assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config)
%the goal of this function is to streamline the training data assembly for
%my different neural network models
%list_of_features_to_add is a string array which indicates what data should
%be added for each neural network
%assembled data will be a cell array the same length as list of features
%where each item in the cell array contains the data specified in
%list_of_features_to_add

assembled_data = cell(1,size(list_of_features_to_add,2));
for i=1:size(list_of_features_to_add,2)
    current_feature = list_of_features_to_add(i);
    switch current_feature
        case "grades"
            assembled_data{i} =  flatten_grades_caller(blind_pass_table,config);
        case "mean waveform"
            assembled_data{i} = get_mean_waveform_from_table(blind_pass_table);
        case "histograms"
            assembled_data{i} = get_histograms_from_bp_table(blind_pass_table);
        case "universal_rank"
            assembled_data{i} = get_universal_rank_caller(blind_pass_table,config);
        case "under_unit"

        case "size"
            assembled_data{i} =  get_size_of_cluster_from_bp_table(blind_pass_table);
    end
end

end