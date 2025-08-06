function [cell_array_of_cluster_groups,ungrouped_clusters] = check_cluster_groups_for_consistent_overlap(cell_array_of_cluster_groups,config)
nn_struct = importdata(config.FP_TO_COMPLEX_MERGE_OR_DONT_NN);
nn = nn_struct.net;
ungrouped_clusters = [];
for i=1:size(cell_array_of_cluster_groups,2)
    current_group = cell_array_of_cluster_groups{i};

    %overlap matrix is a symmetrical matrix which determines if item n
    %overlaps with item m
    %obviously item n overlaps with itself the diagonal will always be 1
    same_underlying_unit = eye(size(current_group,1),size(current_group,1));

    %now we must determine which items in this group overlap with each
    %other
    %we do this because while in the previous step
        %determine_which_blind_pass_neurons_overlap.m
    %example to explain:
        %Neuron A is the first member of the group
        %Neuron A is compared to and deemed combinable with Neuron B
        %Neuron A is compared to and deemed combinable with Neuron C
        %Neuron B is NOT combinable with Neuron C
        %combinable is not a transitive property
    %to solve this problem we add an additional step to see if we can split
    %our groups into further groups

    [lower_diag_row,lower_diag_col] = find(tril(ones(size(same_underlying_unit,1),size(same_underlying_unit,1)),-1));

    %do a custom slicing to make the checking process parallel
    cell_array_of_cluster_checks = cell(size(lower_diag_col,1),1);
    for j=1:size(cell_array_of_cluster_checks,1)
        cell_array_of_cluster_checks{j} = [current_group(lower_diag_row(j),:);current_group(lower_diag_col(j),:)];
    end

    to_be_updated = zeros(1,size(lower_diag_row,1));
    number_of_its = size(lower_diag_row,1);

    parfor j=1:size(lower_diag_row,1)
        current_data = cell_array_of_cluster_checks{j};
        row_ts = current_data{1,"timestamps"}{1};
        row_mean_waveform = current_data{1,"mean_waveform_rep_wire_1"}{1};
        row_grades = cell2mat(current_data{1,"grades"}{1}(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST));

        col_ts = current_data{2,"timestamps"}{1};
        col_mean_waveform = current_data{2,"mean_waveform_rep_wire_1"}{1};
        col_grades = cell2mat(current_data{2,"grades"}{1}(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST));

        current_overlap_percentage = get_overlap_percentage_between_2_cluster_ts(row_ts,col_ts,config);

        data_for_nn =[row_mean_waveform,col_mean_waveform,row_grades,col_grades,current_overlap_percentage] ;

        mergable_or_not_probabilities = predict(nn,data_for_nn);
        [~,index_of_max] = max(mergable_or_not_probabilities);
        to_be_updated(j) = index_of_max-1;
        print_status_iter_message("check_cluster_groups_for_consistent_overlap.m",[i,j],number_of_its);
    end
    
    %now we update our overlap matrix 
    for j=1:size(lower_diag_row,1)
        same_underlying_unit(lower_diag_row(j), lower_diag_col(j)) = to_be_updated(j);
        same_underlying_unit(lower_diag_col(j), lower_diag_row(j)) = to_be_updated(j);
    end
    % figure;
    % heatmap(same_underlying_unit);

    %navigate your same_underlying_unit_matrix
    %any units that do not have at least 90% same underlying units will
    %be removed from the current group and added to another possible group
    indexes_to_remove = [];
    for j=1:size(same_underlying_unit,1)
        if sum(same_underlying_unit(j,:),"all") / size(same_underlying_unit,1) < 0.8
            ungrouped_clusters = [ungrouped_clusters;current_group(j,:)];
            indexes_to_remove = [indexes_to_remove;j];
        end
    end
    
    current_group(indexes_to_remove, :) = []; % Remove non-overlapping units from the current group
    cell_array_of_cluster_groups{i} = current_group;
end

end