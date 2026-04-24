function [tp_array,tn_array,fp_array,fn_array] = get_simple_grouping_tp_fp_tn_fn_scores(blind_pass_table,config,all_certainties_required,number_of_nn_that_need_to_agree)

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


config_parallel = parallel.pool.Constant(config);
locations_parallel = parallel.pool.Constant(locations);




tp_array = [];
tn_array = [];
fp_array = [];
fn_array = [];

for i=1:size(blind_pass_table,1)-1


    %now label that cluster as grouped
    is_grouped(i) = 1;

    % now we can use parallel processes to maximize the number of
    % comparisons

    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    print_status_bar(size(blind_pass_table,1)-1,"Finished row "+string(i)+" so far: get_simple_grouping_tp_fp_tn_fn_scores.m")



    tp_sheet = zeros(length(number_of_nn_that_need_to_agree), length(all_certainties_required));
    tn_sheet = zeros(length(number_of_nn_that_need_to_agree), length(all_certainties_required));
    fp_sheet = zeros(length(number_of_nn_that_need_to_agree), length(all_certainties_required));
    fn_sheet = zeros(length(number_of_nn_that_need_to_agree), length(all_certainties_required));
    cluster_1 = blind_pass_table(i,:);
    parfor j=i+1:size(blind_pass_table,1)

        
        cluster_2 = blind_pass_table(j,:);
        is_same_unit = cluster_2{1,"Max_Overlap_Unit"} == cluster_1{1,"Max_Overlap_Unit"};
        %get the overlap between the 2 clusters
        cluster_1_ts = cluster_1{1,"timestamps"}{1};
        cluster_2_ts = cluster_2{1,"timestamps"}{1};
        [overlap,~,~]=find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config_parallel.Value.TIME_DELTA);
        overlap = overlap * 100;
        if overlap <= 5
            if is_same_unit
                fn_sheet = fn_sheet + 1;
            else
                tn_sheet = tn_sheet + 1;
            end
            send(q,[]);
            continue;
        end



        %get the mean waveform, size, and rep wire for each cluster
        list_of_features_to_add = ["mean_waveform_rep_wire_1","size","rep_wire"];
        cluster_1_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,cluster_1,config);
        cluster_2_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,cluster_2,config);

        %get the euclidean distance between cluster 1 & 2's rep waveforms
        left_clust_wfs = rescale(cluster_1_assembled_data{1});

        right_clust_wfs = rescale(cluster_2_assembled_data{1});
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


        if euc_distance_between_rep_wfs > 220
            send(q,[])
            if is_same_unit
                % fprintf("\n")
                % % disp("False skip")
                % fprintf("\n")
                fn_sheet = fn_sheet +1;
            else
                tn_sheet = tn_sheet + 1;

            end
            continue;
        end





        %put all the data together for the neural network
        %training_data = [training_overlap,training_euc_distance_between_rep_wires,training_euc_distance_between_rep_wfs,training_left_col_size,training_right_col_size];
        nn_data = [overlap,euc_distance_between_rep_wires,euc_distance_between_rep_wfs];

        %get predicted class
        all_predictions = zeros(length(cell_array_of_nets),length(all_certainties_required));
        for k=1:length(cell_array_of_nets)
            net = cell_array_of_nets{k};
            scores = predict(net,nn_data);
            %if the absolute difference between the probabilities is very low
            %AKA 50/50 chance or something akin
            %we'll default to not merging as we care more about false merges

            all_predictions(k,:) = scores(2) >= all_certainties_required;

        end

        YPred = sum(all_predictions,1) >= number_of_nn_that_need_to_agree.';




        if is_same_unit
            tp_sheet = tp_sheet + YPred;
            fn_sheet = fn_sheet + ~YPred;
        else
            fp_sheet = fp_sheet + YPred;
            tn_sheet = tn_sheet + ~YPred;
        end




        send(q,[]);
    end

    tp_array = cat(3,tp_array,tp_sheet);
    tn_array = cat(3,tn_array,tn_sheet);
    fn_array = cat(3,fn_array,fn_sheet);
    fp_array = cat(3,fp_array,fp_sheet);


    fprintf("\n");
        % fprintf("Failed to merge %i clusters | Falsely skipped %i clusters | improperly merged %i clusters: \n",failed_to_merge_count,false_skip_count,false_merge_count);
    fprintf("Stats: TP %i | TN %i | FN %i | FP %i |\n",sum(tp_array,"all"),sum(tn_array,'all'),sum(fn_array,'all'),sum(fp_array,'all'))
end


end
