function [grouped_clusters] = simple_grouping_parallel_ensemble(blind_pass_table,config,track_faliures)
all_nets = struct2table(dir(fullfile(config.DIR_TO_GROUP_OR_NOT_COUNCIL,"*.mat")));
all_nets.folder = string(all_nets.folder);
all_nets.name = string(all_nets.name);
net_names = split(strrep((all_nets.name),".mat",""),"_");
net_numbers = str2double(net_names(:,end));
all_nets.net_numbers = net_numbers;
all_nets = sortrows(all_nets,"net_numbers");

cell_array_of_nets = cell(height(all_nets),1);
for i=1:length(cell_array_of_nets)
    cell_array_of_nets{i} = importdata(fullfile(all_nets{i,"folder"},all_nets{i,"name"}));
end

if ~ismember("Max_Overlap_Unit",string(blind_pass_table.Properties.VariableNames))
    disp("Blind Pass Table Does not have Max_Overlap_unit so we will not track faliures")
    track_faliures = false;
end

%get the raw data required for the neural network
list_of_features_to_add = ["grades 3"];
grades_array = cell2mat(assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config));

%get a table which displays all the nets that we
table_of_nets = struct2table(dir(fullfile(config.dir_of_prob_dist_nets,"*.mat")));
net_names = string(table_of_nets.name);
split_net_names = split(net_names,"_");
[~,where_below_ends ]= find(split_net_names=="below");
net_nums = arrayfun(@(i) split_net_names(i, where_below_ends(i)+1), ...
    (1:size(split_net_names,1))');

%sort the nets by their threshold so that we have an ordered list of
%thresholds
table_of_nets.threshold = str2double(net_nums);
table_of_nets = sortrows(table_of_nets,"threshold","ascend");

%get the all the certainties for the all the grades
[~,unscaled_certainties ]= get_certainties_of_all_previous_nets(string(table_of_nets.name),config.dir_of_prob_dist_nets,grades_array);
disp("Finished getting certainties first time")

%use the first 5 nets
%those first 5 are trained to identify above/below thresholds [1, 2, 3, 4, 5]
%while none of the nets are 100% accurate they all have 88%+ accuracy
%we will take the consensus of their outputs as a way to filter out
%clusters that have less than 5% accuracy
first_five_certainties = unscaled_certainties(:,1:5);

%unscaled_certainties is a nx91 array where each value ranges between [-1,1]
%n: number of rows in blind_pass_table
%91: the number of thresholds that we have a neural network to identify
%above/below
%network 1 is for threshold 1
%network 2 is for threshold 2
%...
%network 91 is for threshold 91
%Certainty Close to 1 : indicates the network i is highly certain that row n has a higher
% accuracy than threshold i
%Certainty Close to -1: indicates the network i is highly certain that row n has a lower
% accuracy than threshold i
%Certainty Close to 0: indicates the network is not certain one way or
%the other

%if the majority of the first 5 networks all determine with a high degree of certainty
%that the example is above the first 5 thresholds then we can likely mark
%it as MUA and continue
elimination_condition =~(sum(first_five_certainties>=.9,2)>3);
blind_pass_table(elimination_condition, :) = [];
% unscaled_certainties(elimination_condition,:) = [];
disp("Determined that "+string(sum(elimination_condition,"all"))+" were MUA and eliminated them from process")


%build arrray to identify which clusters are already grouped
is_grouped = zeros(size(blind_pass_table,1),1);

%add og index to the blind pass table to enable us to keep track of it for
%is_grouped usage
blind_pass_table.og_idx = (1:size(blind_pass_table,1)).';

%get the x,y locations of the channels on the probe
locations = get_probe_xy();

%make the blind_pass_table a parallel variable
% blind_pass_table = parallel.pool.Constant(blind_pass_table);
% config = parallel.pool.Constant(config);
% locations = parallel.pool.Constant(locations);


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
    to_add_to_group = [blind_pass_table{i,"og_idx"}];


    %now label that cluster as grouped
    is_grouped(i) = 1;

    % now we can use parallel processes to maximize the number of
    % comparisons
    possible_additions = find(~is_grouped);
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    print_status_bar(sum(~is_grouped),"Created "+string(group_tracker)+" groups so far: logical_grouping.m")

    false_skip_count = 0;
    false_merge_count = 0;
    failed_to_merge_count = 0;

    parfor j=1:length(possible_additions)

        cluster_1 = blind_pass_table(i,:);
        cluster_2 = blind_pass_table(possible_additions(j),:);

        %get the overlap between the 2 clusters
        cluster_1_ts = cluster_1{1,"timestamps"}{1};
        cluster_2_ts = cluster_2{1,"timestamps"}{1};
        [overlap,~,~]=find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config.TIME_DELTA);
        overlap = overlap * 100;
        if overlap <=5
            send(q,[]);
            if (cluster_2{1,"Max_Overlap_Unit"} == cluster_1{1,"Max_Overlap_Unit"})
                % disp("false skip")
                false_skip_count = false_skip_count+1;
            end
            continue;
        end



        %get the mean waveform, size, and rep wire for each cluster
        list_of_features_to_add = ["mean_waveform_rep_wire_1","size","rep_wire"];
        cluster_1_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,cluster_1,config);
        cluster_2_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,cluster_2,config);

        %get the euclidean distance between cluster 1 & 2's rep waveforms
        %left_clust_wfs = rescale(cluster_1_assembled_data{1});
        left_clust_wfs = cluster_1_assembled_data{1};

        %right_clust_wfs = rescale(cluster_2_assembled_data{1});
        right_clust_wfs = cluster_2_assembled_data{1}; %NOTE TO SELF THIS MIGHT BE WRONG I CANT REMEMBER WHETHER I RESCALED THE WF or not DOUBLE CHECK
        euc_distance_between_rep_wfs = sqrt(sum((left_clust_wfs - right_clust_wfs).^2, 'all'));

        % if euc_distance_between_rep_wfs >70
        %     send(q,[]);
        %     continue;
        % end

        %get the euclidean distance between cluster 1 and 2's rep wires
        rep_wire_for_left_clust_test_data = cluster_1_assembled_data{3};
        rep_wire_for_left_clust_test_data_loc = locations(rep_wire_for_left_clust_test_data,:);
        rep_wire_for_right_clust_test_data = cluster_2_assembled_data{3};
        rep_wire_for_right_clust_test_data_loc = locations(rep_wire_for_right_clust_test_data,:);
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
                false_skip_count = false_skip_count+1;
            end
            continue;
        end
        if euc_distance_between_rep_wfs > 220
            send(q,[])
            if cluster_1{1,"Max_Overlap_Unit"} ==cluster_2{1,"Max_Overlap_Unit"}
                false_skip_count = false_skip_count+1;
            end
            continue;
        end

        


        %put all the data together for the neural network
        %training_data = [training_overlap,training_euc_distance_between_rep_wires,training_euc_distance_between_rep_wfs,training_left_col_size,training_right_col_size];
        nn_data = [overlap,euc_distance_between_rep_wires,euc_distance_between_rep_wfs];

        %get all the scores from all the neural networks
        all_predictions = zeros(length(cell_array_of_nets),1);
        for k=1:length(cell_array_of_nets)
            net = cell_array_of_nets{k};
            scores = predict(net,nn_data);
            %if the absolute difference between the probabilities is very low
            %AKA 50/50 chance or something akin
            %we'll default to not merging as we care more about false merges

            all_predictions(k,:) = scores(2) >= 0.95;

        end

        YPred = all(all_predictions >= 0.95); % we want to be very strict/certain because corruption could cause lots of unnecessary work
        % scores = predict(net,nn_data);

        %if the absolute difference between the probabilities is very low
        %AKA 50/50 chance or something akin
        %we'll default to not merging as we care more about false merges

        if ~YPred
            send(q,[]);
            if track_faliures
                if cluster_1{1,"Max_Overlap_Unit"} ==cluster_2{1,"Max_Overlap_Unit"}
                    false_skip_count = false_skip_count+1;
                end
            end
            continue;
        end

        if YPred
            to_add_to_group = [to_add_to_group;cluster_2{1,"og_idx"}];
            if track_faliures
                if blind_pass_table{cluster_2{1,"og_idx"},"Max_Overlap_Unit"} ~= cluster_1{1,"Max_Overlap_Unit"}
                    % disp("false merge")
                    false_merge_count = false_merge_count+1;
                end
            end
        end
        if track_faliures
            if (cluster_2{1,"Max_Overlap_Unit"} == cluster_1{1,"Max_Overlap_Unit"}) && YPred==0
                % disp("failed to merge")
                failed_to_merge_count = failed_to_merge_count+1;
            end
        end
        send(q,[]);
    end

    fprintf("\n");
    fprintf("Grouped %i clusters\n",length(to_add_to_group));
    if track_faliures
        fprintf("Failed to merge %i clusters | Falsely skipped %i clusters | improperly merged %i clusters: \n",failed_to_merge_count,false_skip_count,false_merge_count);
    end
    % now form the group
    grouped_clusters{group_tracker} = blind_pass_table(to_add_to_group,:);

    %now update is grouped
    is_grouped(to_add_to_group) = 1;

    %now increment the group tracker to start a new group
    group_tracker = group_tracker+1;
end
grouped_clusters = grouped_clusters(~cellfun(@isempty,grouped_clusters));

end