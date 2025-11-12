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
        overlap = overlap * 100;
        if overlap <=5
            send(q,[]);
            if (cluster_2{1,"Max_Overlap_Unit"} == cluster_1{1,"Max_Overlap_Unit"})
                disp("false skip")
            end
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

        % if euc_distance_between_rep_wfs >70
        %     send(q,[]);
        %     continue;
        % end

        %get the euclidean distance between cluster 1 and 2's rep wires
        rep_wire_for_left_clust_test_data = cluster_1_assembled_data{3};
        rep_wire_for_left_clust_test_data_loc = locations_parallel.Value(rep_wire_for_left_clust_test_data,:);
        rep_wire_for_right_clust_test_data = cluster_2_assembled_data{3};
        rep_wire_for_right_clust_test_data_loc = locations_parallel.Value(rep_wire_for_right_clust_test_data,:);
        euc_distance_between_rep_wires = sqrt(sum((rep_wire_for_left_clust_test_data_loc - rep_wire_for_right_clust_test_data_loc).^2, "all"));

        %get the size of the left/right cluster
        % cluster_1_size = cluster_1_assembled_data{2};
        % cluster_2_size = cluster_2_assembled_data{2};

       %before we get to the neural network we need to to make some common
       %sense checks to prevent merges that shouldn't even be considered
       % very low overlap <1% indicates some of these cases
       if overlap < 0.1
           send(q,[])
           if cluster_1{1,"Max_Overlap_Unit"} ==cluster_2{1,"Max_Overlap_Unit"}
               fprintf("\n")
               disp("False skip")
               fprintf("\n")
           end
           continue;
       end 
       if euc_distance_between_rep_wfs > 220
           send(q,[])
           if cluster_1{1,"Max_Overlap_Unit"} ==cluster_2{1,"Max_Overlap_Unit"}
               fprintf("\n")
               disp("False skip")
               fprintf("\n")
           end
           continue;
       end 

       %if they share a rep wire then we expect a higher than average
       %overlap, without a higher overlap then we assume it shouldn't be
       %merged
       % if rep_wire_for_left_clust_test_data == rep_wire_for_right_clust_test_data && overlap <0.5
       %     send(q,[]);
       %     if cluster_1{1,"Max_Overlap_Unit"} ==cluster_2{1,"Max_Overlap_Unit"}
       %         fprintf("\n")
       %         disp("False skip")
       %         fprintf("\n")
       %     end
       %     continue;
       % end

       %if you have a small euclidean distance between rep wires then we
       %expect a higher overlap, if that doesn't happen then we skip
       %merging
       % if euc_distance_between_rep_wires < 40 && overlap < .30 && euc_distance_between_rep_wfs > 100
       %     send(q,[]);
       %     if cluster_1{1,"Max_Overlap_Unit"} ==cluster_2{1,"Max_Overlap_Unit"}
       %         fprintf("\n")
       %         disp("False skip")
       %         fprintf("\n")
       %     end
       %     continue;
       % end


        %put all the data together for the neural network
        %training_data = [training_overlap,training_euc_distance_between_rep_wires,training_euc_distance_between_rep_wfs,training_left_col_size,training_right_col_size];
        nn_data = [overlap,euc_distance_between_rep_wires,euc_distance_between_rep_wfs];

        %get predicted class
        scores = predict(net,nn_data);

        %if the absolute difference between the probabilities is very low
        %AKA 50/50 chance or something akin
        %we'll default to not merging as we care more about false merges

        if abs(scores(1)-scores(2)) <.20
            send(q,[]);
            continue;
        end
        [~,YPred] = max(scores,[],2);
        YPred = YPred-1;

        if YPred
            to_add_to_group = [to_add_to_group;cluster_2{1,"og_idx"}];
            if blind_pass_table{cluster_2{1,"og_idx"},"Max_Overlap_Unit"} ~= cluster_1{1,"Max_Overlap_Unit"}
                disp("false merge")
            end
        end
        if (cluster_2{1,"Max_Overlap_Unit"} == cluster_1{1,"Max_Overlap_Unit"}) && YPred==0
                disp("failed to merge")
        end
        send(q,[]);
    end

    fprintf("\n");
    fprintf("Grouped %i clusters\n",length(to_add_to_group));
    % now form the group
    grouped_clusters{group_tracker} = bp_table_parallel.Value(to_add_to_group,:);

    %now update is grouped
    is_grouped(to_add_to_group) = 1;

    %now increment the group tracker to start a new group
    group_tracker = group_tracker+1;
end
grouped_clusters = grouped_clusters(~cellfun(@isempty,grouped_clusters));

end