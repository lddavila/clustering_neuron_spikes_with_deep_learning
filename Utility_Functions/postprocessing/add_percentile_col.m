function [cell_array_of_cluster_groups] = add_percentile_col(cell_array_of_cluster_groups,config)
nn_struct = importdata(config.FP_TO_COMPLEX_CHOOSE_BETTER_NN);
choose_better_nn = nn_struct.net;
for i=1:size(cell_array_of_cluster_groups,2)
    current_data = cell_array_of_cluster_groups{i};

    %get grades for the current data
    [grade_names,all_grades]= flatten_grades_cell_array(current_data{:,"grades"},config);
    [indexes_of_grades_were_looking_for,~] = find(ismember(grade_names,config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST)));
    grades_array = all_grades(:,indexes_of_grades_were_looking_for);
    
    %now get a list of all possible ways to select 2 clusters at a time
    all_combos_of_2_clusters = nchoosek(1:height(current_data),2);

    
    %remove any rows where a cluster is compared to itself
    all_combos_of_2_clusters(all_combos_of_2_clusters(:,1)==all_combos_of_2_clusters(:,2)) = [];
    
    %now use a custom table slicing to enable parallel processing
    cell_array_of_comparisons = cell(size(all_combos_of_2_clusters,1),1);
    cell_array_of_grades= cell(size(all_combos_of_2_clusters,1),1);
    cell_array_of_is_left_better_counts= cell(size(all_combos_of_2_clusters,1),1);
    for j=1:size(cell_array_of_comparisons,1)
        cell_array_of_comparisons{j} = current_data([all_combos_of_2_clusters(j,1),all_combos_of_2_clusters(j,2)],["mean_waveform_rep_wire_1","timestamps"]);
        cell_array_of_grades{j} = grades_array([all_combos_of_2_clusters(j,1),all_combos_of_2_clusters(j,2)],:);
        cell_array_of_is_left_better_counts{j} = 0;
    end



%     % assemble the neural network data
% data_for_nn = [mean_waveform_array(all_possible_combos(random_indexes,1),:),...
%     grades_array(all_possible_combos(random_indexes,1),:),...
%     mean_waveform_array(all_possible_combos(random_indexes,2),:),...
%     grades_array(all_possible_combos(random_indexes,2),:),...
%     random_sample_indexes,...
%     left_is_better_col];
    parfor j=1:size(cell_array_of_comparisons,1)
        current_sample_of_two = cell_array_of_comparisons{j};
        current_data_grades = cell_array_of_grades{j};
        current_data_mean_wfms = cell2mat(current_sample_of_two{:,"mean_waveform_rep_wire_1"});
        current_overlap = get_overlap_percentage_between_2_cluster_ts(current_sample_of_two{1,"timestamps"}{1},current_sample_of_two{2,"timestamps"}{1},config);
        left_size = size(current_sample_of_two{1,"timestamps"}{1},1);
        right_size = size(current_sample_of_two{2,"timestamps"}{1},1); 
        %table_of_nn_data = array2table([shuffled_data_for_nn(:,1:end-1),overlap_col,first_size_col(:,1),sec_size_col(:,1),shuffled_data_for_nn(:,end)]);

        data_for_nn = [current_data_mean_wfms(1,:),current_data_grades(1,:),current_data_mean_wfms(2,:),current_data_grades(2,:),current_overlap,left_size,right_size];
        left_is_better_probabilities = predict(choose_better_nn,data_for_nn);
        [~,is_better] = max(left_is_better_probabilities);
        cell_array_of_is_left_better_counts{j} = is_better-1;
    end

    matrix_of_counts = zeros(size(current_data,1),size(current_data,1));

    for j=1:size(all_combos_of_2_clusters,1)
        current_row = all_combos_of_2_clusters(j,1);
        current_col = all_combos_of_2_clusters(j,2);
        if cell_array_of_is_left_better_counts{j}==1
            matrix_of_counts(current_row,current_col) = cell_array_of_is_left_better_counts{j};
        else
            matrix_of_counts(current_col,current_row) =  1;
        end
    end

    %now calculate the percentile for each of these
    %the percentile is the sum of how many you're better than /
    %(size(matrix,2)-1
    percentile = 100 *(sum(matrix_of_counts,2) ./ (size(matrix_of_counts,2)-1));
    current_data.("Percentile") = percentile;
   cell_array_of_cluster_groups{i} = current_data; 
   disp("finished "+string(i));
end
end