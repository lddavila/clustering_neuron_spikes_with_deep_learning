function [new_groups]= add_group_tags_col(groups,config)
%the goal of this function is to try and enhance our groups formed by
%simple_grouping_parallel.m 
%we'll do this by cycling through the already members of the already formed groups and seeing if
%they would have been merged into any of the other groups
%the assumption being that if they could have been merged with any of the
%other groups they're likely multi-unit-activity

%import the net to predict grouping
net = importdata(config.FP_TO_SIMPLE_GROUP_OR_DONT_NN);

%add group tags
for i=1:length(groups)
    groups{i}.("group_tags") = mat2cell(repelem(i,size(groups{i},1),1),ones(size(groups{i},1),1));
end

%concatenate all of them into a single table for simplicity
bp_table =vertcat(groups{:});
bp_table.og_idx = (1:size(bp_table,1)).';

%create a matrix to keep track of which clusters are tagged to each group
tags_mat = nan(size(bp_table,1),length(groups));
%create a dataqueue to track prograss
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
print_status_bar(size(tags_mat,1),"add_group_tags_col.m")
bp_table_parallel = parallel.pool.Constant(bp_table);
config_parallel = parallel.pool.Constant(config);
locations_parallel = parallel.pool.Constant(get_probe_xy());
sliced_tags_matrix = slice_table_for_parallel_processing(tags_mat,[]);
parfor i=1:size(tags_mat,1)
    cluster_1 = bp_table_parallel.Value(i,:);
    cluster_1_ts = cluster_1{1,"timestamps"}{1};
    %get the mean waveform, size, and rep wire for each cluster
    list_of_features_to_add = ["mean_waveform_rep_wire_1","size","rep_wire"];
    cluster_1_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,cluster_1,config);
    current_cluster_tag = cluster_1{1,"group_tags"}{1};
    all_group_tags = sliced_tags_matrix{i};
    all_group_tags(current_cluster_tag) =1;
    for j=1:size(bp_table,1)
        %don't group to yourself
        if i==j
            % send(q,[]);
            continue;
        end
        %if you've already proven that you can be tagged to this group then
        %there's no need to check if it can be tagged again
        if ~isnan(all_group_tags(bp_table_parallel.Value{j,"group_tags"}{1}))
            % send(q,[]);
            continue;
        end
        cluster_2 = bp_table(j,:);
       
        
        %if a cluster has already been confirmed to be combinable with
        %other groups then we don't need to continue to compare it against
        %more groups, it's already MUA
        if sum(all_group_tags,"all",'omitmissing') >2
            % send(q,[]);
            continue;
        end

       
        %now actually check for groupability
        %get the overlap between the 2 clusters
        
        cluster_2_ts = cluster_2{1,"timestamps"}{1};
        [overlap,~,~]=find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config_parallel.Value.TIME_DELTA);
        overlap = overlap * 100;

        
        
        cluster_2_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,cluster_2,config);

        %get the euclidean distance between cluster 1 & 2's rep waveforms
        left_clust_wfs = rescale(cluster_1_assembled_data{1});

        right_clust_wfs = rescale(cluster_2_assembled_data{1});
        euc_distance_between_rep_wfs = sqrt(sum((left_clust_wfs - right_clust_wfs).^2, 'all'));

        %get the euclidean distance between cluster 1 and 2's rep wires
        rep_wire_for_left_clust_test_data = cluster_1_assembled_data{3};
        rep_wire_for_left_clust_test_data_loc = locations_parallel.Value(rep_wire_for_left_clust_test_data,:);
        rep_wire_for_right_clust_test_data = cluster_2_assembled_data{3};
        rep_wire_for_right_clust_test_data_loc = locations_parallel.Value(rep_wire_for_right_clust_test_data,:);
        euc_distance_between_rep_wires = sqrt(sum((rep_wire_for_left_clust_test_data_loc - rep_wire_for_right_clust_test_data_loc).^2, "all"));

        nn_data = [overlap,euc_distance_between_rep_wires,euc_distance_between_rep_wfs];

        %get predicted class
        scores = predict(net,nn_data);

        if scores(2) > 0.96
            all_group_tags(cluster_2{1,"group_tags"}{1}) = 1;
        end
        % send(q,[]);
    end
    sliced_tags_matrix{i} = all_group_tags;
    
    send(q,[]);
end
tags_mat = cell2mat(sliced_tags_matrix);
for i=1:size(bp_table,1)
    [~,new_group_tags] = find(tags_mat(i,:)==1);
    bp_table{i,"group_tags"} = {new_group_tags};
end

new_groups = reform_groups_based_on_tags(bp_table);
end