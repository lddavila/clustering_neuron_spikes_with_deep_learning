function [clusters_organized_by_same_group] = determine_which_blind_pass_neurons_overlap_parallel(blind_pass_table,config)
%differs from the original because it makes the mergable checks in parallel and is
%faster (theoretically)
clusters_organized_by_same_group = cell(1,size(blind_pass_table,1));
already_merged = zeros(size(blind_pass_table,1),1);
nn_struct = importdata(config.FP_TO_COMPLEX_MERGE_OR_DONT_NN);
nn = nn_struct.net;
[grade_names,all_grades]= flatten_grades_cell_array(blind_pass_table{:,"grades"},config);
[indexes_of_grades_were_looking_for,~] = find(ismember(grade_names,config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST)));
grades_array = all_grades(:,indexes_of_grades_were_looking_for);
cluster_group_counter = 1;
blind_pass_table.("orig_index") = (1:size(blind_pass_table,1)).';
for i=1:size(blind_pass_table,1)
    if already_merged(i)
        %print_status_iter_message("determine_which_blind_pass_neurons_overlap.m",cluster_group_counter,sum(~already_merged));
        continue;
    end
    current_neuron_ts = blind_pass_table{i,"timestamps"}{1};
    already_merged(i) = 1;
    current_neuron_waveform = blind_pass_table{i,"mean_waveform_rep_wire_1"}{1};
    current_neuron_grades = grades_array(i,:);

    still_mergable_data = blind_pass_table(~already_merged,:);

    cut_down_data = still_mergable_data(:,["timestamps","mean_waveform_rep_wire_1","orig_index"]);

    sliced_still_mergable_data = slice_table_for_parallel_processing(cut_down_data,[]);
    sliced_grades_array = slice_table_for_parallel_processing(grades_array(~already_merged,:),[]);

    mergable_clusters = [blind_pass_table(i,["timestamps","mean_waveform_rep_wire_1","orig_index"])];
    indexes_to_merge = [];
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    print_status_bar    (sum(~already_merged),"Created "+string(cluster_group_counter)+" groups so far: determine_which_blind_pass_neurons_overlap_parallel.m")
    parfor j=1:size(sliced_still_mergable_data,1)
        current_data = sliced_still_mergable_data{j};
        compare_neuron_ts = current_data{1,"timestamps"}{1};
        compare_neuron_waveform = current_data{1,"mean_waveform_rep_wire_1"}{1};
        compare_neuron_grades = sliced_grades_array{j};


        %current_overlap_percentage = get_overlap_percentage_between_2_cluster_ts(compare_neuron_ts,current_neuron_ts,config);
        [current_overlap_ratio,~,~] = find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(compare_neuron_ts,current_neuron_ts,config.TIME_DELTA);
        current_overlap_percentage = current_overlap_ratio * 100;
        %     data_for_nn = [mean_waveform_array(all_possible_combos(random_indexes,1),:),...
        % mean_waveform_array(all_possible_combos(random_indexes,2),:),...
        % grades_array(all_possible_combos(random_indexes,1),:),...
        % grades_array(all_possible_combos(random_indexes,2),:),...
        % random_sample_indexes,...
        % combinable_or_not_col];
        data_for_nn =[current_neuron_waveform,compare_neuron_waveform,current_neuron_grades,compare_neuron_grades,current_overlap_percentage] ;
        mergable_or_not_probabilities = predict(nn,data_for_nn);
        [~,index_of_max] = max(mergable_or_not_probabilities);
        is_mergable = index_of_max-1;
        if is_mergable
            mergable_clusters = [mergable_clusters;current_data];
            indexes_to_merge = [indexes_to_merge;current_data{1,"orig_index"}];
        end
        send(q,[]);

    end
    clusters_organized_by_same_group{cluster_group_counter} = blind_pass_table(mergable_clusters{:,"orig_index"},:);
    already_merged(indexes_to_merge) = 1;
    cluster_group_counter = cluster_group_counter+1;
end
clusters_organized_by_same_group = cluster_group_counter(1:cluster_group_counter-1);
end