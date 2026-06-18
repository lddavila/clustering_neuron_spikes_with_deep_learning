function [toy_clusters_table] = get_cluster_accuracy_for_toy_data(toy_clusters_table,cell_array_of_gt_idxs,cell_array_of_cores)
overlap_cell_arrays = cell(height(toy_clusters_table),1);
max_overlap_perc = zeros(height(toy_clusters_table),1);
max_accuracy = zeros(height(toy_clusters_table),1);
max_overlap_unit_array = zeros(height(toy_clusters_table),1);
num_iterations = size(toy_clusters_table,1);
percentage_of_gt_cores_in_tetrode = zeros(height(toy_clusters_table),1);
cell_array_of_gt_cores = cell(height(toy_clusters_table),1);
cell_array_of_all_gt_cores = cell(height(toy_clusters_table),1);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
print_status_bar(num_iterations,"get_cluster_accuracy_for_toy_data.m")

sliced_toy_clusters = slice_table_for_parallel_processing(toy_clusters_table);
parfor i=1:height(toy_clusters_table)
    current_data = sliced_toy_clusters{i};
    current_cluster_idx = current_data{1,"cluster_idx"}{1};
    max_overlap_unit = -inf;
    max_overlap_percentage = 0;
    accuracy = 0;
    local_overlap = zeros(length(cell_array_of_gt_idxs),1);
    for j=1:length(cell_array_of_gt_idxs)
        tp = sum(ismember(cell_array_of_gt_idxs{j},current_cluster_idx)); %in cluster and in ground truth
        fn = length(cell_array_of_gt_idxs{j}) -tp; %in ground truth but not in cluster
        fp = length(current_cluster_idx) - tp; %in cluster but not in ground truth
        tn = 0; %always zero due to nature of the data
        overlap_perc =(  tp / length(cell_array_of_gt_idxs{j})) * 100;

        if overlap_perc > max_overlap_percentage
            max_overlap_unit = j;
            max_overlap_percentage = overlap_perc;
            accuracy = ((tp + tn) / (fn + fp + tp + tn)) * 100;
        end
        local_overlap(j) = overlap_perc;

    end
    %check how many of the "ground truth cores" appear in the current
    %tetrode

    if max_overlap_percentage==0
        cell_array_of_all_gt_cores{i} = [];
        cell_array_of_gt_cores{i} = [];
        percentage_of_gt_cores_in_tetrode(i) = 0;
    else
        curr_gt_cores = cell_array_of_cores{max_overlap_unit};

        cell_array_of_all_gt_cores{i} = curr_gt_cores;
        curr_channels = current_data{1,"channels"};
        in_curr_tetr = curr_channels(ismember(curr_channels,curr_gt_cores));
        cell_array_of_gt_cores{i} = in_curr_tetr;
        percentage_of_gt_cores_in_tetrode(i) = (length(in_curr_tetr) / length(curr_gt_cores)) * 100;
    end
    

    overlap_cell_arrays{i} = local_overlap;
    max_overlap_unit_array(i) = max_overlap_unit;
    max_overlap_perc(i) = max_overlap_percentage;
    max_accuracy(i) = accuracy;
    send(q,[]);
end
toy_clusters_table.("Max_Overlap_perc_With_Unit") = max_overlap_perc;
toy_clusters_table.("Max_Overlap_Unit") = max_overlap_unit_array;
toy_clusters_table.("overlap_perc_with_all_units") = overlap_cell_arrays;
toy_clusters_table.("accuracy") = max_accuracy;
toy_clusters_table.("gt_cores_in_tetr") = cell_array_of_gt_cores;
toy_clusters_table.("perc_of_gt_cores_in_tetr") = percentage_of_gt_cores_in_tetrode;
toy_clusters_table.("all_gt_cores") = cell_array_of_all_gt_cores;
end