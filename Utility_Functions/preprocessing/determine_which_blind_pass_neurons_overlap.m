function [clusters_organized_by_same_group] = determine_which_blind_pass_neurons_overlap(blind_pass_table,config)
clusters_organized_by_same_group = {};
already_merged = zeros(size(blind_pass_table,1),1);
if config.ON_HPC
    nn_struct = importdata();
else
    nn_struct = importdata(config.FP_TO_COMPLEX_MERGE_OR_DONT_NN);
end
nn = nn_struct.net;
[grade_names,all_grades]= flatten_grades_cell_array(blind_pass_table{:,"grades"},config);
[indexes_of_grades_were_looking_for,~] = find(ismember(grade_names,config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST)));
grades_array = all_grades(:,indexes_of_grades_were_looking_for);
cluster_group_counter = 1;
for i=1:size(blind_pass_table,1)
    if already_merged(i)
        print_status_iter_message("determine_which_blind_pass_neurons_overlap.m",i,sum(~already_merged));
        continue;
    end
    clusters_organized_by_same_group{cluster_group_counter} = blind_pass_table(i,:);
    current_neuron_ts = blind_pass_table{i,"timestamps"}{1};
    already_merged(i) = 1;
    current_neuron_waveform = blind_pass_table{i,"Mean Waveform"}{1};
    current_neuron_grades = grades_array(i,:);
    for j=i+1:size(blind_pass_table,1)
        if already_merged(j)
            print_status_iter_message("determine_which_blind_pass_neurons_overlap.m",[i,j],sum(~already_merged));
            continue;
        end
        compare_neuron_ts = blind_pass_table{j,"timestamps"}{1};
        compare_neuron_waveform = blind_pass_table{i,"Mean Waveform"}{1};
        compare_neuron_grades = grades_array(i,:);

        [~,index_of_larger ]= max([length(compare_neuron_ts),length(current_neuron_ts)]);
        [smaller_cluster_size,~ ]= min([length(compare_neuron_ts),length(current_neuron_ts)]);
        if index_of_larger==1
            %if the larger cluster is the compare neuron then we use the ts
            %of the current neuron as our compare
            number_of_timestamps_in_common = find_number_of_true_positives_given_a_time_delta_hpc(current_neuron_ts,compare_neuron_ts,config.TIME_DELTA);
        elseif index_of_larger==2
            %if the larger cluster is the current_neuron then we use the ts
            %of the compare neuron as our compare
            %the logic behind this is that the first set of ts that are put
            %into the function will never be over counted
            number_of_timestamps_in_common = find_number_of_true_positives_given_a_time_delta_hpc(compare_neuron_ts,current_neuron_ts,config.TIME_DELTA);
        else
            number_of_timestamps_in_common=0;
        end
        current_overlap_percentage = (number_of_timestamps_in_common / smaller_cluster_size) * 100;

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
            clusters_organized_by_same_group{cluster_group_counter} = [clusters_organized_by_same_group{cluster_group_counter};blind_pass_table(j,:)];
            already_merged(j) = 1;
        end
        print_status_iter_message("determine_which_blind_pass_neurons_overlap.m",[i,j],sum(~already_merged));

    end
    cluster_group_counter = cluster_group_counter+1;


end
end