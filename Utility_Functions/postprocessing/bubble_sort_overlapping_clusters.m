function [best_rep,table_of_other_appearences] = bubble_sort_overlapping_clusters(table_of_other_appearences,config,choose_better_net)
best_rep = NaN;

if size(table_of_other_appearences,1)==1
    best_rep = 1;
    return;
end

% to get the best rep we must compare the grades, 
% and then essentially bubble sort them
% we then perform the choose best among all best


%compare every permutation to see which one chooses better
unsorted_table_of_other_appearences = table_of_other_appearences;

%get the grades
[grade_names,all_grades]= flatten_grades_cell_array(table_of_other_appearences{:,"grades"},config);
[indexes_of_grades_were_looking_for,~] = find(ismember(grade_names,config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST)));
grades_array = all_grades(:,indexes_of_grades_were_looking_for);

all_permutations_of_comparisons = nchoosek(1:size(table_of_other_appearences,1),2);



overlap_col = get_overlap_percentage_for_nn_training_data(table_of_other_appearences,all_permutations_of_comparisons,config);

% data_for_nn = [mean_waveform_array(all_possible_combos(random_indexes,1),:),...
%     grades_array(all_possible_combos(random_indexes,1),:),...
%     mean_waveform_array(all_possible_combos(random_indexes,2),:),...
%     grades_array(all_possible_combos(random_indexes,2),:),...
%     random_sample_indexes,...
%     left_is_better_col];%

%array2table([shuffled_data_for_nn(:,1:end-1),overlap_col,first_size_col(:,1),sec_size_col(:,1),shuffled_data_for_nn(:,end)]);
%
%now run the buble sort
% disp("Before Sort")
% disp(table_of_other_appearences)
for counter=1:size(table_of_other_appearences,1)
    swapped=0;
    for current_wave_ind =1:size(table_of_other_appearences,1)-counter
        cluster_1_wave= table_of_other_appearences{current_wave_ind,"Mean Waveform"}{1};
        cluster_2_wave = table_of_other_appearences{current_wave_ind+1,"Mean Waveform"}{1};
        grades_1 = grades_array(current_wave_ind,:);
        grades_2 = grades_array(current_wave_ind+1,:);
        first_cluster_size =size(table_of_other_appearences{current_wave_ind,"timestamps"}{1},1);
        sec_cluster_size =size(table_of_other_appearences{current_wave_ind+1,"timestamps"}{1},1);
        overlap = overlap_col(all_permutations_of_comparisons(:,1)==current_wave_ind & all_permutations_of_comparisons(:,2)==current_wave_ind+1);


        data_for_nn = [cluster_1_wave,grades_1,cluster_2_wave,grades_2,overlap,first_cluster_size,sec_cluster_size];

        is_cluster_1_better_probabilities = predict(choose_better_net,data_for_nn);
        [~,max_index] = max(is_cluster_1_better_probabilities);
        is_wave_1_better = max_index-1;
        if is_wave_1_better
            temp_row = table_of_other_appearences(current_wave_ind,:);
            table_of_other_appearences(current_wave_ind,:) = table_of_other_appearences(current_wave_ind+1,:);
            table_of_other_appearences(current_wave_ind+1,:) = temp_row;
            swapped=true;
        end
    end
    if ~swapped
        break;
    end
end

z_score_cond = unsorted_table_of_other_appearences{:,"Z Score"} ==table_of_other_appearences{end,"Z Score"};
tetr_cond = unsorted_table_of_other_appearences{:,"Tetrode"} == table_of_other_appearences{end,"Tetrode"};
cluster_cond = unsorted_table_of_other_appearences{:,"Cluster"} ==table_of_other_appearences{end,"Cluster"};

best_rep = find(z_score_cond & cluster_cond & tetr_cond);
end