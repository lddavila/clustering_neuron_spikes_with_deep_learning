function [faliure_metrics] = test_simplest_group_or_dont_on_new_recording(test_data,number_of_comparisons_per_class,fp_to_net)
config = spikesort_config();

%get the x,y locations of the channels on the probe
locations = get_probe_xy();

%remove any data that has accuracy less than 10
test_data = test_data(test_data{:,"accuracy"}>10,:);

net = importdata(fp_to_net);

all_test_comparisons = nchoosek(1:size(test_data,1),2);

%get the true class for the test data comparisons
test_true_class = test_data{all_test_comparisons(:,1),"Max_Overlap_Unit"} ==test_data{all_test_comparisons(:,2),"Max_Overlap_Unit"} ;


%select number_of_comparisons_per_class
test_comparisons_with_class_1 = find(test_true_class);
test_comparisons_with_class_0 = find(~test_true_class);

test_class_1_idxs = randperm(length(test_comparisons_with_class_1),number_of_comparisons_per_class);
test_class_0_idxs = randperm(length(test_comparisons_with_class_0),number_of_comparisons_per_class);

%combine these idxs into a single array
all_test_idxs = [test_class_0_idxs,test_class_1_idxs];

%get the assembled data for the true class
list_of_features_to_add = ["mean_waveform_rep_wire_1","size","rep_wire"];
test_assembled_data = assemble_data_for_neural_net(list_of_features_to_add,test_data,config);

%get the size of the left and right clusters
test_left_clust_size = test_assembled_data{2}(all_test_comparisons(all_test_idxs,1));
test_right_clust_size = test_assembled_data{2}(all_test_comparisons(all_test_idxs,2));

%get the euclidean distances between the left/right cluster waveforms
left_clust_wfs = test_assembled_data{1}(all_test_comparisons(all_test_idxs,1));
right_clust_wfs = test_assembled_data{1}(all_test_comparisons(all_test_idxs,2));
test_euc_distance_between_rep_wfs = vecnorm(left_clust_wfs - right_clust_wfs, 2, 2);

%get the overlap feature for all the test comparisons
test_overlap = nan(length(all_test_idxs),1);
for i=1:length(test_overlap)
    cluster_1_ts = test_data{all_test_comparisons(all_test_idxs(i),1),"timestamps"}{1};
    cluster_2_ts = test_data{all_test_comparisons(all_test_idxs(i),2),"timestamps"}{1};
    [test_overlap(i),~,~]=find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config.TIME_DELTA);
end
test_overlap = test_overlap * 100;

%now get the euclidean distance from the rep wires of all the test comparisons
rep_wire_for_left_clust_test_data = test_assembled_data{3}(all_test_comparisons(all_test_idxs,1));
rep_wire_for_left_clust_test_data_loc = locations(rep_wire_for_left_clust_test_data,:);
rep_wire_for_right_clust_test_data = test_assembled_data{3}(all_test_comparisons(all_test_idxs,2));
rep_wire_for_right_clust_test_data_loc = locations(rep_wire_for_right_clust_test_data,:);
test_euc_distance_between_rep_wires = vecnorm(rep_wire_for_left_clust_test_data_loc - rep_wire_for_right_clust_test_data_loc,2, 2);

%now assemble the test data
%training_data = [training_overlap,training_euc_distance_between_rep_wires,training_euc_distance_between_rep_wfs,training_left_col_size,training_right_col_size];
%OG LINE test_data = [test_overlap,test_euc_distance_between_rep_wires,test_euc_distance_between_rep_wfs,test_left_clust_size,test_right_clust_size];
test_data = [test_overlap,test_euc_distance_between_rep_wires,test_euc_distance_between_rep_wfs];
%append the true class to the end of the test data
test_data = [test_data,[test_true_class(all_test_idxs)]];

%shuffle the test data
test_data = test_data(randperm(size(test_data,1),size(test_data,1)),:);

%now test the trained neural network on never before seen comparisons
scores = predict(net,test_data(:,1:end-1));
[~,YPred] = max(scores,[],2);
YPred = YPred-1;

accuracy = sum(YPred==test_data(:,end))/size(test_data,1);

%print out a statement to reflect accuracy
fprintf("Accuracy on test data: %.2f",accuracy*100);

%Faliure break down
rows_where_the_net_failed = find(YPred ~= test_data(:,end));


faliure_metrics = cell2table(cell(0,5),'VariableNames',["waveform_diff","dist_btwn_rep_wires","overlap","failure_type","probabilities"]);

%test_data = [test_overlap,test_euc_distance_between_rep_wires,test_euc_distance_between_rep_wfs,test_left_clust_size,test_right_clust_size];
for i=1:length(rows_where_the_net_failed)
    f_idx = rows_where_the_net_failed(i);
    if test_data(f_idx,end)== 1
        faliure_type = "failed to merge";
    else
        faliure_type = "improperly merges";
    end
    probabilities = scores(f_idx,:);
    %OG LINE: current_row = table(test_data(f_idx,3),test_data(f_idx,2),test_data(f_idx,4),test_data(f_idx,5),test_data(f_idx,1),faliure_type,'VariableNames',["waveform_diff","dist_btwn_rep_wires","left_cluster_size","right_cluster_size","overlap","failure_type"]);
    current_row = table(test_data(f_idx,3),test_data(f_idx,2),test_data(f_idx,1),faliure_type,probabilities,'VariableNames',["waveform_diff","dist_btwn_rep_wires","overlap","failure_type","probabilities"]);
    faliure_metrics = [faliure_metrics;current_row];
end

% y_true over ALL evaluated comparisons (1 = should merge, 0 = not)
y_true_all   = test_data(:,end);        % last column you appended is GT
p_merge_all  = scores(:,2);             % second column = P(merge)

% Precision–Recall curve for the MERGE class (positive = 1)
[rec, prec, T] = perfcurve(y_true_all, p_merge_all, 1, ...
    'xCrit','reca','yCrit','prec');

figure; plot(rec, prec, 'LineWidth', 2); grid on
xlabel('Recall'); ylabel('Precision'); title('PR curve (merge class)')

% Choose threshold for target precision
targetPrecision = 0.95;
idx = find(prec >= targetPrecision, 1, 'last');
if isempty(idx)
    warning('No threshold achieves %.2f precision. Max precision = %.3f', ...
            targetPrecision, max(prec));
    [~,idx] = max(prec);   % pick best available
end
tau = T(idx);
fprintf('Use τ = %.3f (Precision %.3f, Recall %.3f)\n', tau, prec(idx), rec(idx));

end