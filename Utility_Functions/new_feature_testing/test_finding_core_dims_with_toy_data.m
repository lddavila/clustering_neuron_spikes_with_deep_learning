% set paths
home_dir = cd("..");
cd("..");
addpath(genpath(fullfile(pwd,"Utility_Functions")));
addpath(genpath(fullfile(pwd,"clustering-master")));
cd(home_dir);
% get config
disp("Finished adding path");
config = spikesort_config;
disp("Finished getting config");
% get/generate toy data to use
dir_to_save_these_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"testing_toy_data"));
if ~contains(pwd,"10595")
    toy_data_struct = importdata("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\toy_data\toy_data.mat");
    cell_array_of_gt_idxs = toy_data_struct.gt_idxs;
    cell_array_of_cores = toy_data_struct.cores;
    X = toy_data_struct.X;
    waveforms=toy_data_struct.aligned;
else
    [cell_array_of_gt_idxs,cell_array_of_cores,X,waveforms] = generate_toy_clustering_data(100,300000,100,false,config,dir_to_save_these_results_to);
end
disp("Finished getting toy data");
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
if ~isfile(fullfile(dir_to_save_these_results_to,"technically_findable.mat"))
    technically_findable_units = cell(size(all_combos,1),1);
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


    par_save(fullfile(dir_to_save_these_results_to,"technically_findable.mat"),technically_findable_units);
else
    technically_findable_units = importdata(fullfile(dir_to_save_these_results_to,"technically_findable.mat"));
end
disp("Finished getting technically findable units");

% cluster = parcluster("Processes");
% num_workers = max(1, floor(cluster.NumWorkers / 4));
% fprintf("Have %i workers\n",num_workers);
poolobj = parpool("Processes",8);
%save the waveform data into files that match all_combos so that we can
%effeciently run the clustering in a parfor loop
dir_with_sliced_data = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_these_results_to,"sliced_toy_data"));
for i=1:size(waveforms,1)
    dim_i_data = abs(X(:,i));
    dim_i_wf = waveforms(i,:,:);
    data_struct = struct();
    data_struct.wf = dim_i_wf;
    data_struct.peaks = dim_i_data;
    par_save(fullfile(dir_with_sliced_data,"dim_"+string(i)+".mat"));
    disp("Finished saving "+string(i)+"/"+size(waveforms,1));
end

% now run the clustering for each of those 2 dimensional combos to see what units are findable through clusters
% I THINK it would be best to track this on per neuron basis so we'll start
% with getting the results from assembling every pair of 2
cell_array_of_toy_clusters_tables = cell(size(all_combos,1),1);
[toy_clusters,tetrode_arrays] = test_tinkering_around_phase_using_toy_data(X,cell_array_of_gt_idxs,cell_array_of_cores,config,all_combos,dir_to_save_these_results_to,dir_with_sliced_data);
toy_clusters_table = table(vertcat(toy_clusters{:}),(1:1:size(tetrode_arrays,1)).',tetrode_arrays,'VariableNames',["cluster_idx","cluster","channels"]);
[toy_clusters_table] = get_cluster_accuracy_for_toy_data(toy_clusters_table,cell_array_of_gt_idxs,cell_array_of_cores);
disp("Finished getting the toy clusters table");





