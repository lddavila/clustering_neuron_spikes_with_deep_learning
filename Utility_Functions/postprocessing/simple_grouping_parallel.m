function [grouped_clusters] = simple_grouping_parallel(blind_pass_table,config)
net = importdata(config.FP_TO_SIMPLE_GROUP_OR_DONT_NN);

%build arrray to identify which clusters are already grouped
is_grouped = zeros(size(blind_pass_table,1),1);

%add og index to the blind pass table to enable us to keep track of it for
%is_grouped usage
blind_pass_table.og_idx = (1:size(blind_pass_table,1)).';

%get the x,y locations of the channels on the probe
locations = get_probe_xy();

%make the blind_pass_table a parallel variable
bp_table_parallel = parallel.pool.Constant(blind_pass_table);
config_parallel = parallel.pool.Constant(config);
locations_parallel = parallel.pool.Constant(locations);


%now use a for loop to navigate through all of the clusters in the
%blind_pass_table
grouped_clusters = cell(size(blind_pass_table,1),1);
group_tracker = 1;

for i=1:size(blind_pass_table,1)
    %check to ensure that the current cluster hasn't been grouped
    if is_grouped(i)
        continue;
    end

    %if the current cluster isn't grouped then we'll add it to the next
    %empty group
    to_add_to_group = [bp_table_parallel.Value{i,"og_idx"}];


    %now label that cluster as grouped
    is_grouped(i) = 1;

    % now we can use parallel processes to maximize the number of
    % comparisons
    possible_additions = find(~is_grouped);
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    print_status_bar(sum(~is_grouped),"Created "+string(group_tracker)+" groups so far: logical_grouping.m")


    parfor j=1:length(possible_additions)
        
        cluster_1 = bp_table_parallel.Value(i,:);
        cluster_2 = bp_table_parallel.Value(possible_additions(j),:);

        %get the overlap between the 2 clusters
        cluster_1_ts = cluster_1{1,"timestamps"}{1};
        cluster_2_ts = cluster_2{1,"timestamps"}{1};
        [overlap,~,~]=find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config_parallel.Value.TIME_DELTA);

        if overlap <=0.10
            send(q,[]);
            continue;
        end

        %get the mean waveform, size, and rep wire for each cluster
        list_of_features_to_add = ["mean_waveform_rep_wire_1","size","rep_wire"];
        cluster_1_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,cluster_1,config);
        cluster_2_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,cluster_2,config);

        %get the euclidean distance between cluster 1 & 2's rep waveforms
        left_clust_wfs = cluster_1_assembled_data{1};
        right_clust_wfs = cluster_2_assembled_data{1};
        euc_distance_between_rep_wfs = sqrt(sum((left_clust_wfs - right_clust_wfs).^2, 'all'));

        if euc_distance_between_rep_wfs >70
            send(q,[]);
            continue;
        end

        %get the euclidean distance between cluster 1 and 2's rep wires
        rep_wire_for_left_clust_test_data = cluster_1_assembled_data{3};
        rep_wire_for_left_clust_test_data_loc = locations_parallel.Value(rep_wire_for_left_clust_test_data,:);
        rep_wire_for_right_clust_test_data = cluster_2_assembled_data{3};
        rep_wire_for_right_clust_test_data_loc = locations_parallel.Value(rep_wire_for_right_clust_test_data,:);
        euc_distance_between_rep_wires = sqrt(sum((rep_wire_for_left_clust_test_data_loc - rep_wire_for_right_clust_test_data_loc).^2, "all"));

        %get the size of the left/right cluster
        cluster_1_size = cluster_1_assembled_data{2};
        cluster_2_size = cluster_2_assembled_data{2};

        %put all the data together for the neural network
        %training_data = [training_overlap,training_euc_distance_between_rep_wires,training_euc_distance_between_rep_wfs,training_left_col_size,training_right_col_size];
        nn_data = [overlap,euc_distance_between_rep_wires,euc_distance_between_rep_wfs,cluster_1_size,cluster_2_size];

        %get predicted class
        scores = predict(net,nn_data);
        [~,YPred] = max(scores,[],2);
        YPred = YPred-1;

        if YPred
            to_add_to_group = [to_add_to_group;cluster_2{1,"og_idx"}];
            fprintf("");
        end
        send(q,[]);
    end

    fprintf("\n");
    % now form the group
    grouped_clusters{group_tracker} = bp_table_parallel.Value(to_add_to_group,:);

    %now update is grouped
    is_grouped(to_add_to_group) = 1;

    %now increment the group tracker to start a new group
    group_tracker = group_tracker+1;
end
grouped_clusters = grouped_clusters(~cellfun(@isempty,grouped_clusters));

end