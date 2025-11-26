function [collapsed_groups] = collapse_groups(cell_array_of_cluster_groups,config,number_of_representatives_per_group)
%the goal of this function is to solve the problem of repititions aka false
%positives
%currently we have a problem of over representation in our cluster groups
%for example we produce 105 cluster groups when only 100 ground truth units
%actually exist
%originally we attempted to solve this problem by using the percentile
%feature to pick the best representation of each cluster (where best is defined by the percentile feature) group and check
%for mergability based off those best representations
%unfortunatley this caused overmerging
%so let us instead try checking for collapsible groups by looking at the
%top n best representations and ensuring they can all be merged

%step 1 will be to get the n clusters with the highest percentile from each cluster group
group_representatives = cell(number_of_representatives_per_group,1);
for i=1:length(cell_array_of_cluster_groups)
    current_data = sortrows(cell_array_of_cluster_groups{i},"Percentile",'descend');

    if size(current_data,1)==1
        mid_points=1;
    else
        mid_point = round(size(current_data,1)/2);
        mid_points = mid_point:min([size(current_data,1),mid_point+number_of_representatives_per_group-1]);

    end
    

    current_data.og_group = repelem(i,size(current_data,1),1);
    group_representatives{i} = current_data(mid_points,:);
end

%with the groups created we'll now get every permutation of their
%combinations 
all_possible_combinations = nchoosek(1:length(group_representatives),2);
cell_array_of_group_reps = cell(size(all_possible_combinations,1),1);
delete(gcp('nocreate'));
parpool("Threads");
parfor i=1:length(all_possible_combinations)
    cell_array_of_group_reps{i} = vertcat(group_representatives{all_possible_combinations(i,:)});
end

%now that we have the representations we can check them for mergability
nn_struct = importdata(config.FP_TO_COMPLEX_MERGE_OR_DONT_NN);
nn= nn_struct.net;
%     data_for_nn = [mean_waveform_array(all_possible_combos(random_indexes,1),:),...
% mean_waveform_array(all_possible_combos(random_indexes,2),:),...
% grades_array(all_possible_combos(random_indexes,1),:),...
% grades_array(all_possible_combos(random_indexes,2),:),...
% random_sample_indexes,...
% combinable_or_not_col];

mergable_flags = zeros(length(cell_array_of_group_reps),1);
q = parallel.pool.DataQueue;
afterEach(q,@print_message_using_dataqueue)
print_message_using_dataqueue(length(cell_array_of_group_reps), " checking for collapsible groups")
parfor i=1:length(cell_array_of_group_reps)
    current_representatives = cell_array_of_group_reps{i};

    groups_represented = groupcounts(current_representatives,"og_group");

    %get the mean wfs for every cluster
    mean_wf_for_current = vertcat(current_representatives{current_representatives{:,"og_group"}==groups_represented{1,"og_group"},"mean_waveform_rep_wire_1"}{:});
    mean_wf_for_compare = vertcat(current_representatives{current_representatives{:,"og_group"}==groups_represented{2,"og_group"},"mean_waveform_rep_wire_1"}{:});

    %get the grades for each cluster
    [grade_names,all_grades]= flatten_grades_cell_array(current_representatives{:,"grades"},config);
    [indexes_of_grades_were_looking_for,~] = find(ismember(grade_names,config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST)));
    current_rep_grades = all_grades(current_representatives{:,"og_group"}==groups_represented{1,"og_group"},indexes_of_grades_were_looking_for);
    compare_rep_grades = all_grades(current_representatives{:,"og_group"}==groups_represented{2,"og_group"},indexes_of_grades_were_looking_for);

    %get the overlap between clusters that are not in the same group and
    %test for mergability with the pre trained neural network
    array_of_overlap_percentages = zeros(1,size(current_representatives,1));
    is_mergable_array =  zeros(1,size(current_representatives,1));

    group_1_ts = current_representatives(current_representatives{:,"og_group"}==groups_represented{1,"og_group"},"timestamps");
    group_2_ts = current_representatives(current_representatives{:,"og_group"}==groups_represented{2,"og_group"},"timestamps");

    place_in_array_counter = 1;
    for j=1:size(group_1_ts,1)
        current_neuron_ts = group_1_ts{j,"timestamps"}{1};
        for k=1:size(group_2_ts,1)
            compare_neuron_ts = group_2_ts{k,"timestamps"}{1};
            array_of_overlap_percentages(place_in_array_counter)= get_overlap_percentage_between_2_cluster_ts(compare_neuron_ts,current_neuron_ts,config);
            data_for_nn =[mean_wf_for_current(j,:),mean_wf_for_compare(k,:),current_rep_grades(j,:),compare_rep_grades(k,:),array_of_overlap_percentages(place_in_array_counter)];
            mergable_or_not_probabilities = predict(nn,data_for_nn);
            [~,index_of_max] = max(mergable_or_not_probabilities);
            is_mergable_array(place_in_array_counter)= index_of_max-1;
            place_in_array_counter = place_in_array_counter+1;
        end
    end
  %  disp(array_of_overlap_percentages);
    if sum(is_mergable_array)==length(is_mergable_array)
        mergable_flags(i)=1;
    end
    send(q,[]);
end
collapsed_groups = cell(1,sum(mergable_flags));
non_collapsed_groups = zeros(length(cell_array_of_cluster_groups),1);
%now we collpase the groups based on what was found
mergable_counter = 1;
for i=1:length(mergable_flags)
    if ~mergable_flags(i)
        continue;
    end
    current_representatives = cell_array_of_group_reps{i};

    groups_represented = groupcounts(current_representatives,"og_group");
    collapsed_groups{mergable_counter} = vertcat(cell_array_of_cluster_groups{groups_represented{:,"og_group"}});
    non_collapsed_groups(groups_represented{:,"og_group"}) =1;
    mergable_counter = mergable_counter+1;
end
collapsed_groups = [collapsed_groups,cell_array_of_cluster_groups(~non_collapsed_groups)];
end