function [estimated_rank] = add_universal_rank(current_data_waveform,current_data_grades,current_data_size,presorted_table,choose_better_nn,presorted_grade_rows,current_ts,config)

%REMEMBER!!! HIGHER RANK IS BETTER
%BECAUSE PRESORTED_TABLE IS IN ASCENDING ORDER
estimated_rank = nan;

class_predictions = [1000 1];
compare_position = round(size(presorted_table,1)/2);
num_iterations = 0;

% data_for_nn = [mean_waveform_array(all_possible_combos(random_indexes,1),:),...
%     grades_array(all_possible_combos(random_indexes,1),:),...
%     mean_waveform_array(all_possible_combos(random_indexes,2),:),...
%     grades_array(all_possible_combos(random_indexes,2),:),...
%     random_sample_indexes,...
%     left_is_better_col];

% rlap_col = get_overlap_percentage_for_nn_training_data(blind_pass_table,remaining_idxs,config);

% cluster_size_col = cell2mat(cellfun(@size, blind_pass_table{:,"timestamps"}, 'UniformOutput', false));
% table_of_nn_data = array2table([shuffled_data_for_nn(:,1:end-1),overlap_col,first_size_col(:,1),sec_size_col(:,1),shuffled_data_for_nn(:,end)]);

end_of_range = size(presorted_table,1);
beginning_of_range = 1;
last_five_compare_ranks = nan(1,5);
while abs(class_predictions(1) - class_predictions(2)) > 0.05 && num_iterations<1000
    compare_waveform = presorted_table{compare_position,"mean_waveform_rep_wire_1"}{1};
    compare_grades = presorted_grade_rows(compare_position,:);
    compare_size = size(presorted_table{compare_position,"timestamps"}{1},1);

    overlap_between_clusters = get_overlap_percentage_between_2_cluster_ts(presorted_table{compare_position,"timestamps"}{1},current_ts,config);




    data_for_nn = [current_data_waveform,current_data_grades,compare_waveform,compare_grades,overlap_between_clusters,current_data_size,compare_size];

    class_predictions = predict(choose_better_nn,data_for_nn);
    % disp(class_predictions)


    if abs(class_predictions(1) - class_predictions(2)) > 0.05
       
        [~,max_class_position] =max(class_predictions) ;
        current_data_is_better = max_class_position-1;
        if ~current_data_is_better
            beginning_of_range = beginning_of_range;
            end_of_range = compare_position;
            compare_position = round((beginning_of_range+end_of_range)/2);
            if compare_position <=1
                estimated_rank = 1;
                return;
            end
        else
        beginning_of_range = compare_position;
        end_of_range = end_of_range;
        compare_position = round((beginning_of_range+end_of_range)/2);
        if compare_position >= size(presorted_table,1)
            estimated_rank = size(presorted_table,1);
            return;
        end
        end
    else
        estimated_rank = compare_position;
        return;
    end
    num_iterations = num_iterations+1;
    % disp(compare_position)
    if mod(num_iterations,5)==0
        new_position = 5;
    else
        new_position =mod(num_iterations,5);
    end
    last_five_compare_ranks(new_position) = compare_position;
    if all(last_five_compare_ranks(1)==last_five_compare_ranks)
        estimated_rank = last_five_compare_ranks(1);
        return;
    end

    if mod(num_iterations,100)==0
        print_status_iter_message("add_universal_rank.m",num_iterations,1000);
    end

end
estimated_rank = compare_position;
end