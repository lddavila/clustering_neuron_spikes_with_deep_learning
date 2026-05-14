function [should_be_merged] = check_mergability_for_2_clusters_using_group_or_dont_nn(cluster_1_pks,cluster_2_pks,clust_1_filt,clust_2_filt,aligned,config,intersection_size,smaller_cluster_size)

%get the x,y locations of the channels on the probe
locations = get_probe_xy();

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

overlap = intersection_size / smaller_cluster_size;
overlap = overlap * 100;
array_of_cluster_peaks = {cluster_1_pks,cluster_2_pks};
array_of_clust_filts = {clust_1_filt,clust_2_filt};
mean_waveforms = cell(1,length(array_of_cluster_peaks));
compare_wires = [];
current_channels = config.current_channels;
for j=1:length(array_of_cluster_peaks)

    peaks = array_of_cluster_peaks{j}.';
    % Set up the representative wire for the cluster

    % Set up the representative wire for the cluster
    [~, max_wire] = max(peaks, [], 1);
    poss_wires = unique(max_wire);
    n = histc(max_wire, poss_wires);
    [~, max_n] = max(n);
    compare_wire = poss_wires(max_n);
    mean_waveform = mean(shiftdim(aligned(compare_wire, array_of_clust_filts{j}, :), 1));
    mean_waveform = mean_waveform - mean(mean_waveform);
    mean_waveforms{j} = mean_waveform;
    compare_wires = [compare_wires,current_channels(compare_wire)];

end
rep_wire_for_left_clust_test_data_loc = locations(compare_wires(1),:);
rep_wire_for_right_clust_test_data_loc = locations(compare_wires(2),:);
euc_distance_between_rep_wires = sqrt(sum((rep_wire_for_left_clust_test_data_loc - rep_wire_for_right_clust_test_data_loc).^2, "all"));

left_clust_wfs = rescale(mean_waveforms{1});

right_clust_wfs = rescale(mean_waveforms{2});
euc_distance_between_rep_wfs = sqrt(sum((left_clust_wfs - right_clust_wfs).^2, 'all'));

%put all the data together for the neural network
%training_data = [training_overlap,training_euc_distance_between_rep_wires,training_euc_distance_between_rep_wfs,training_left_col_size,training_right_col_size];
nn_data = [overlap,euc_distance_between_rep_wires,euc_distance_between_rep_wfs];

%get predicted class
all_predictions = zeros(length(cell_array_of_nets),1);
for k=1:length(cell_array_of_nets)
    net = cell_array_of_nets{k};
    scores = predict(net,nn_data);
    %if the absolute difference between the probabilities is very low
    %AKA 50/50 chance or something akin
    %we'll default to not merging as we care more about false merges

    all_predictions(k,:) = scores(2) >= 0.9; % we need extreme certainty at this stage because a false merge could cause explosion downstram

end

should_be_merged = all(all_predictions); %strict certainty requirement all NNs need to be highly certain
end