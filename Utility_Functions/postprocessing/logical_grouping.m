function [grouped_clusters,failed_grouping] = logical_grouping(blind_pass_table,config,track_failed_grouping)
%the goal of this function is to group the clusters using logic instead of a neural network

%build arrray to identify which clusters are already grouped
is_grouped = zeros(size(blind_pass_table,1),1);

%add og index to the blind pass table to enable us to keep track of it for
%is_grouped usage
blind_pass_table.og_idx = (1:size(blind_pass_table,1)).';

%make the blind_pass_table a parallel variable
bp_table_parallel = parallel.pool.Constant(blind_pass_table);

%get the x,y locations of the channels on the probe
locations = get_probe_xy();

%now use a for loop to navigate through all of the clusters in the
%blind_pass_table
grouped_clusters = cell(size(blind_pass_table,1),1);
group_tracker = 1;

failed_grouping = [];
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


    locations_parallel = parallel.pool.Constant(locations);

    % now we can use parallel processes to maximize the number of
    % comparisons
    possible_additions = find(~is_grouped);
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    print_status_bar(sum(~is_grouped),blind_pass_table{1,"recording_name"} +" Created "+string(group_tracker)+" groups so far: logical_grouping.m")

    for j=1:length(possible_additions)
        cluster_2_idx = possible_additions(j);
        is_mergable = false;
        %get the cluster data for comparisons
        cluster_1 = bp_table_parallel.Value(i,:);
        cluster_2 = bp_table_parallel.Value(cluster_2_idx,:);
        %if it isn't already grouped then start running our logical tests
        %to see if they can be grouped or not

        %we'll do this through process of elimination

        %get the channels for cluster 1
        cluster_1_grades = cluster_1{1,"grades"}{1};
        cluster_1_channels = cluster_1_grades{49};

        %do the same for cluster 2
        cluster_2_grades = cluster_2{1,"grades"}{1};
        cluster_2_channels = cluster_2_grades{49};

        have_same_tetrode = cluster_1{1,"Tetrode"} == cluster_2{1,"Tetrode"};

        have_same_z_score = cluster_1{1,"Z Score"} == cluster_2{1,"Z Score"};

        
        % have_channels_in_common = ~isempty(intersect(cluster_1_channels,cluster_2_channels));



        %if they have the same z score and tetrode then logically they cannot be the same cluster
        %this is because we assume that clusters on the same configuration
        %do not overlap with each other
        if have_same_z_score && have_same_tetrode
            send(q,[]);
            continue;
        end


        %get the overlap between the 2 clusers
        cluster_1_ts = cluster_1{1,"timestamps"}{1};
        cluster_2_ts = cluster_2{1,"timestamps"}{1};
        [overlap,~,~] =find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config.TIME_DELTA);

        %another helpful test is checking to see if the cluster we are
        %trying to add shares a z score and tetrode with any previously
        %added clusters
        %the logic to eliminate these is the same logic we use to
        other_z_scores = blind_pass_table{to_add_to_group,"Z Score"} == cluster_2{1,"Z Score"};
        other_tetrodes = (blind_pass_table{to_add_to_group,"Tetrode"} == cluster_2{1,"Tetrode"}).';
        has_match = (other_z_scores == other_tetrodes);
        if (sum(has_match,"all")>0) && (overlap <= 0.1)
            send(q,[]);
            continue;
        end

        %get the euclidean distance between the 2 cluster mean waveforms
       euc_dist_between_waveforms = norm(cluster_1{:,"mean_waveform_rep_wire_1"}{1} - cluster_2{:,"mean_waveform_rep_wire_1"}{1});


        %if they have channels in common then they should have the same rep
        %wire assuming they are the same
        have_same_rep_wire = cluster_1_channels(cluster_1_grades{42}) == cluster_2_channels(cluster_2_grades{42});

        if have_same_rep_wire && have_same_z_score && have_same_tetrode
            send(q,[]);
            continue;
        end
        %if they have channels in common and have the same wire then it's
        %highly likely these represent the same neuron
        if have_same_rep_wire && overlap >0.03
            is_mergable = true;
        end

        
        %if they do not have channels in common nor have rep wiren they still might represent
        %the same neuron 
        %we'll figure out the distance between the rep channels
        loc_of_2_rep_wires = [locations_parallel.Value(cluster_1_channels(cluster_1_grades{42}),:) ; locations_parallel.Value(cluster_2_channels(cluster_2_grades{42}),:)] ;
        rep_wire_norm = norm(loc_of_2_rep_wires(1,:) - loc_of_2_rep_wires(2,:));
        

        %if your eucliden distance (in micrometers is very low then we
        %expect higher overlay)
        %we have to allow for lower overlap ranges as the euclidean
        %distances get further (within reason)
        if rep_wire_norm <= 40 && overlap > .45
            is_mergable =true;
        end
        if rep_wire_norm > 50 && overlap >.40
            is_mergable = true;
        end
        if rep_wire_norm > 60 && overlap >.30 && euc_dist_between_waveforms < 70
            is_mergable = true;
        end
        if rep_wire_norm > 70 && overlap >.20
            is_mergable = true;
        end
        if rep_wire_norm > 80 && overlap >.10 && rep_wire_norm < 100
            is_mergable = true;
        end

        %if we cannot get mergability based off of the euclidean distance
        %of the channels and overlap we'll then try to get it with just the
        %euclidean distance between the average wavefrosm
        if euc_dist_between_waveforms < 120 && overlap>=0.26
            is_mergable = true;
        end

        if is_mergable
            %we make this a nested if statement because if you do not track
            %failed groupings it is assumed that you do not have the max
            %overlap unit col in your table since it is not a simulated
            %recording and this structure prevents the error of trying to
            %access a variable that doesn't exist
            if track_failed_grouping
                if cluster_1{1,"Max_Overlap_Unit"}~=cluster_2{1,"Max_Overlap_Unit"}
                    fprintf("\n")
                    disp(cluster_1(:,["Tetrode","Z Score","Cluster","Max_Overlap_Unit","accuracy"]))
                    disp(cluster_2(:,["Tetrode","Z Score","Cluster","Max_Overlap_Unit","accuracy"]))
                    fprintf("overlap:%.2f\n",overlap);
                    fprintf("rep wire norm:%.2f\n",rep_wire_norm);
                    disp("improper merge")
                    fprintf("euc dist between rep wire wf: %.2f\n",euc_dist_between_waveforms)
                    failed_grouping = [failed_grouping,[cluster_1{1,"Max_Overlap_Unit"},cluster_2{1,"Max_Overlap_Unit"}]];
                end
            end
            to_add_to_group = [to_add_to_group;cluster_2{1,"og_idx"}];
            fprintf("");
            send(q,[]);
            continue;
        end

        %we make this a nested if statement because if you do not track
        %failed groupings it is assumed that you do not have the max
        %overlap unit col in your table since it is not a simulated
        %recording and this structure prevents the error of trying to
        %access a variable that doesn't exist
        if track_failed_grouping
            if ~is_mergable && cluster_1{1,"Max_Overlap_Unit"}==cluster_2{1,"Max_Overlap_Unit"}
                fprintf("\n")
                disp(cluster_1(:,["Tetrode","Z Score","Cluster","Max_Overlap_Unit","accuracy"]))
                disp(cluster_2(:,["Tetrode","Z Score","Cluster","Max_Overlap_Unit","accuracy"]))
                fprintf("overlap:%.2f\n",overlap);
                fprintf("rep wire norm:%.2f\n",rep_wire_norm);
                fprintf("euc dist between rep wire wf: %2f\n",euc_dist_between_waveforms)
                disp("Failed to merge");
                failed_grouping = [failed_grouping,cluster_1{1,"Max_Overlap_Unit"}];
            end
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

%now remove any non filled groups
grouped_clusters = grouped_clusters(~cellfun(@isempty,grouped_clusters));
%display(counter);
end