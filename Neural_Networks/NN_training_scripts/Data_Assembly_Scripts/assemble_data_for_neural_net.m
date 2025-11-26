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
    if current_feature== "grades"
        assembled_data{i} =  flatten_grades_caller(blind_pass_table,config);
    elseif contains(current_feature,"mean_waveform")
        assembled_data{i} = get_mean_waveform_from_table(blind_pass_table,current_feature);
    elseif contains(current_feature,"histogram")
        assembled_data{i} = get_histograms_from_bp_table(blind_pass_table,current_feature);
    elseif current_feature== "universal_rank"
        assembled_data{i} = get_universal_rank_caller(blind_pass_table,config);
    elseif contains(current_feature,"under_unit")
        assembled_data{i} = get_under_unit_info_with_n_levels_of_grad_and_min_threshold_m(blind_pass_table,current_feature);
        %current_feature= "under_unit_gradienceLevelN_minThresholdM";
    elseif current_feature=="size"
        assembled_data{i} =  get_size_of_cluster_from_bp_table(blind_pass_table);
    elseif current_feature == "grades 2"
         temp_data= vertcat(blind_pass_table{:,"grades"}{:});
         assembled_data{i} = cell2mat(temp_data(:,config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST));
    elseif contains(current_feature,"peak_caps")
        assembled_data{i} = get_caps_of_peaks(blind_pass_table,current_feature);
    elseif contains(current_feature,"rep_wire")
        [assembled_data{i},~] = get_rep_wire_for_every_cluster(blind_pass_table);
    elseif contains(current_feature,"channels")
        [~,assembled_data{i}] = get_rep_wire_for_every_cluster(blind_pass_table); 
    elseif current_feature=="above_below"
        assembled_data{i} = get_above_below_probabilities_per_cluster(blind_pass_table);
    elseif contains(current_feature,"valley")
        assembled_data{i} =get_cv_of_valley_feature_of_nn(blind_pass_table,current_feature) ;
    else 
        disp("In list_of_features variable.")
        disp(current_feature)
        disp("Is not a valid feature.")
        disp("assembled_data at "+string(i)+" will be empty.")
    end
end

end