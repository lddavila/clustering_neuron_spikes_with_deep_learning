% set paths
home_dir = cd("..");
cd("..");
addpath(genpath(fullfile(pwd,"Utility_Functions")));
cd(home_dir);
% get config
config = spikesort_config;
% get/generate toy data to use
if ~contains(pwd,"10595")
    toy_data_struct = importdata("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\toy_data\toy_data.mat");
    cell_array_of_gt_idxs = toy_data_struct.gt_idxs;
    cell_array_of_cores = toy_data_struct.cores;
    X = toy_data_struct.X;
    waveforms=toy_data_struct.aligned;
else
    [cell_array_of_gt_idxs,cell_array_of_cores,X,waveforms] = generate_toy_clustering_data(100,100000,100,false,config);
end

% run the toy data through the clustering algorithm
% [toy_clusters,tetrode_arrays] = test_tinkering_around_phase_using_toy_data(X,cell_array_of_gt_idxs,cell_array_of_cores,config,waveforms);
% toy_clusters_table = table(vertcat(toy_clusters{:}),tetrode_arrays,'VariableNames',["cluster_idx","channels"]);
% get which cluster represents which toy ground truth unit
% [toy_clusters_table] = get_cluster_accuracy_for_toy_data(toy_clusters_table,cell_array_of_gt_idxs,cell_array_of_cores);

% try a computational approach
% we want to know how these clusters show up with the clustering algorithm 
% and if there's an ideal number of dimensions that maximizes accuracy
% I think the method I tried above wasn't worthwhile
% I think it might be better instead to design it in the following way

% get every combination of 2 dimensions
all_combos = nchoosek(1:size(X,2),2);

% for each combo find all units that are technically findable on those channels
technically_findable_units = cell(size(all_combos),1);
for i=1:size(all_combos,1)
    current_dimensions = all_combos(i,:);
    local_findable = nan(length(cell_array_of_cores),1);
    for j=1:length(cell_array_of_cores)
        current_clust_cores = cell_array_of_cores{j};
        if any(ismember(current_clust_cores,current_dimensions))
            local_findable(j) = j;
        end
    end
    local_findable(isnan(local_findable)) = [];
    technically_findable_units{i} = local_findable;
end

% now run the clustering for each of those 2 dimensional combos to see what units are findable through clusters
% I THINK it would be best to track this on per neuron basis so we'll start
% with getting the results from assembling every pair of 2 
cell_array_of_toy_clusters_tables = cell(size(all_combos,1),1);
[toy_clusters,tetrode_arrays] = test_tinkering_around_phase_using_toy_data(X,cell_array_of_gt_idxs,cell_array_of_cores,config,waveforms,all_combos);
toy_clusters_table = table(vertcat(toy_clusters{:}),(1:1:size(tetrode_arrays,1)).',tetrode_arrays,'VariableNames',["cluster_idx","cluster","channels"]);
[toy_clusters_table] = get_cluster_accuracy_for_toy_data(toy_clusters_table,cell_array_of_gt_idxs,cell_array_of_cores);
% for i = 1:size(all_combos,1)
%     current_dimensions = all_combos(i,:);
% 
%     toy_clusters_table = table(vertcat(toy_clusters{:}),tetrode_arrays,'VariableNames',["cluster_idx","channels"]);
%     % get which cluster represents which toy ground truth unit
%     [toy_clusters_table] = get_cluster_accuracy_for_toy_data(toy_clusters_table,cell_array_of_gt_idxs,cell_array_of_cores);
%     cell_array_of_toy_clusters_tables{i} = toy_clusters_table;
%     send(q,[])
% end






