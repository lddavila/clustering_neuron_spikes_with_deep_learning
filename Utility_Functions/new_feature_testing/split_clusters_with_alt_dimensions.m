function [blind_pass_table] = split_clusters_with_alt_dimensions(blind_pass_table,config,varargin)
% get timestamps to use
timestamps = importdata(config.TIMESTAMP_FP);
locs_of_channels = get_probe_xy(); %get the x-y locations of the probe channels


%slice the blind pass table by their unique aligned files to minimize
%loading time
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,"fp_to_aligned");

%establish some structs which we'll be used to keep track of the peaks of
%the clusters we'll try to resplit
cell_array_of_new_peak_vals_for_each_bp_table_aligned_row = cell(length(sliced_bp_table),1);
cell_array_of_compare_channels_for_each_bp_table_aligned_row = cell(length(sliced_bp_table),1);

%get the ordered list of channels
ordered_list_of_channels = get_dynamic_ordered_list_of_channels(config);

%set up a dataqueue which will keep track of progress for us
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = length(ordered_list_of_channels);
print_status_bar(num_iterations,"split_clusters_with_alt_dimensions: loading channel data");

%Find and shut down any active parallel pool
existingPool = gcp('nocreate');
if ~isempty(existingPool)
    delete(existingPool);
end

%Start your new thread-based pool
parpool('threads');

% import the channel data which will be used by threads
cell_array_of_channel_data = cell(length(ordered_list_of_channels),1);
channel_dir = config.DIR_WITH_OG_CHANNEL_RECORDINGS;
parfor i=1:length(ordered_list_of_channels)
    cell_array_of_channel_data{i} = importdata(fullfile(channel_dir,ordered_list_of_channels(i)));
    send(q,[]);
end



%set up a dataqueue which will keep track of progress for us
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = length(sliced_bp_table);
print_status_bar(num_iterations,"split_clusters_with_alt_dimensions: getting split data");


parfor i=1:length(sliced_bp_table)

    %get current table
    current_bp_table = sliced_bp_table{i};

    %load the sw
    spike_windows = load(current_bp_table{1,"fp_to_sorted_spike_windows_after_purges"});
    spike_windows = spike_windows.data_to_save;

    %load the aligned
    aligned = load(current_bp_table{1,"fp_to_aligned"});
    aligned = aligned.data_to_save;

    peaks = get_peaks(aligned,true);

    all_sil_scores = cell(height(current_bp_table),1);
    all_davies_scores = nan(height(current_bp_table),1);
    all_calinski_scores = nan(height(current_bp_table),1);

    warning('off', 'stats:pdist2:DataConversion'); %known warning which will not affect result
    cell_array_of_new_peaks_for_current_rows = cell(height(current_bp_table),1);
    cell_array_of_compare_channels_for_current_rows = cell(height(current_bp_table),1);
    for j=1:height(current_bp_table)

        rep_channel_1 =current_bp_table{j,"rep_channel_1"}; %get the channel where the neuron appears clearest
        rep_channel_2 = current_bp_table{j,"rep_channel_2"};

        %get list of all channels within certain distance of current rep wire
        current_rep_wire_loc = locs_of_channels(rep_channel_1,:);
        distance_to_other_rep_wires = vecnorm(current_rep_wire_loc - locs_of_channels, 2, 2);
        nearby_wires = find(distance_to_other_rep_wires<100); %100 here is relative, it doesnt NEED to be this euclidean distance it can be more/less just depends on how you define close we may optimize this meta parameter later


        non_rep_wire_channels_nums = setdiff(nearby_wires,[rep_channel_1,rep_channel_2]);

        cell_array_of_compare_channels_for_current_rows{j} = non_rep_wire_channels_nums;
        cluster_peaks_idx = current_bp_table{j,"cluster_idx"}{1};
        cluster_labels = single(ones(size(peaks,2),1)); %default label everything to be unclustered
        cluster_labels(cluster_peaks_idx) = 2;  %label the current cluster

        rearragned_channel_data = cell_array_of_channel_data(non_rep_wire_channels_nums); %index the channel data so that we can run it in parallel while maintaining the channel labeling

        peaks_data_for_cluster = single(peaks([current_bp_table{j,"rep_wire_1"},current_bp_table{j,"rep_wire_2"}],:).');



        %get the silhouette score assuming the full cluster
        % all_sil_scores{j} = silhouette(peaks_data_for_cluster,cluster_labels);



        %get the calinski & davies scores assuming the full cluster
        eva_cal= evalclusters(peaks_data_for_cluster,cluster_labels,"CalinskiHarabasz");
        all_calinski_scores(j) = eva_cal.CriterionValues;
        eva_dav = evalclusters(peaks_data_for_cluster,cluster_labels,"DaviesBouldin");
        all_davies_scores(j) = eva_dav.CriterionValues;


        cell_array_of_other_channel_peaks = cell(length(rearragned_channel_data),1);
        for k=1:length(rearragned_channel_data)
            compare_channel_data = rearragned_channel_data{k};
            other_tetrode_peaks_on_compare_channel = compare_channel_data(spike_windows(:,4)); %the same times of the peaks that we found on the other tetrode, but on this channel
            compare_channel_cluster_peaks = other_tetrode_peaks_on_compare_channel(cluster_peaks_idx); %get the cluster's appearence on this channel
            cell_array_of_other_channel_peaks{k} = [peaks(blind_pass_table{i,"rep_wire_1"},cluster_peaks_idx).',compare_channel_cluster_peaks];
        end
        cell_array_of_new_peaks_for_current_rows{j} = cell_array_of_other_channel_peaks;
    end
    cell_array_of_new_peak_vals_for_each_bp_table_aligned_row{i} = cell_array_of_new_peaks_for_current_rows;
    cell_array_of_compare_channels_for_each_bp_table_aligned_row{i} = cell_array_of_compare_channels_for_current_rows;
    current_bp_table.calinski_score = all_calinski_scores;
    % current_bp_table.sil_score = all_sil_scores;
    current_bp_table.davies_score = all_davies_scores;
    sliced_bp_table{i} = current_bp_table;
    send(q,[])
end

%with new peaks aquired we can now try and identify when/if a splitting a
%cluster will result in better separation


% extended_blind_pass_table = cell(height(blind_pass_table),1);
cluster_addition = max(blind_pass_table.Cluster)+1;
cell_array_of_new_tables_for_each_al_file = cell(length(sliced_bp_table),1);
% cell_array_of_original_reference_cluster = cell(height(blind_pass_table),1);
warning('off', 'stats:pdist2:DataConversion'); %known warning which will not affect result

for i=1:length(cell_array_of_new_peak_vals_for_each_bp_table_aligned_row) %this outer for loop cycling through the table in such a way that very group is dedicated to 1 aligned file
    current_bp_table = sliced_bp_table{i};
    current_comparison_peaks_for_current_aligned = cell_array_of_new_peak_vals_for_each_bp_table_aligned_row{i};
    curr_comp_ch_for_current_aligned = cell_array_of_compare_channels_for_each_bp_table_aligned_row{i};

    current_z_score = blind_pass_table{i,"Z Score"};
    current_tetrode = blind_pass_table{i,"Tetrode"};

    % accuracies_per_channel = cell(length(curr_comp_ch_for_current_aligned),1);
    tables_per_channel = cell(length(curr_comp_ch_for_current_aligned),1);
    cell_array_of_new_tables_for_each_clust = cell(length(current_comparison_peaks_for_current_aligned),1);
    parfor j=1:length(current_comparison_peaks_for_current_aligned) %this for loop cycles through each cluster that comes from the aligned file specified inside
        current_cluster_alternate_dimension_peaks = current_comparison_peaks_for_current_aligned{j};
        current_alternate_channel_peaks = curr_comp_ch_for_current_aligned{j};
        cell_array_of_new_tables_for_each_channel = cell(length(current_cluster_alternate_dimension_peaks),1);
        for c=1:length(current_cluster_alternate_dimension_peaks) %this for loop cycles through every channel that the cluster might be split by
            fprintf("i:%i j:%i c:%i\n",i,j,c);
            %current_clustering_data = zscore(current_clustering_data,1,1);
            current_clustering_data = current_cluster_alternate_dimension_peaks{c};
            current_alternate_channel = current_alternate_channel_peaks(c);
            current_clustering_data = rescale(current_clustering_data);
            current_clustering_data(:,2) = current_clustering_data(:,2)*2; %I multiply by 2 here because we want to allow the new clustering to give more weight to the second dimension in order to maximize it's splitting potential
            sihlouette_before = evalclusters(current_clustering_data,[ones(size(current_clustering_data,1)-1,1);2],"silhouette"); %since the original cluster is just
            % [epsilon,min_num_dpts,res_x] =find_epsilon_for_db_scan_using_k_distance(current_clustering_data,false,true);
            % new_clusters = dbscan(current_clustering_data,epsilon,min_num_dpts);
            % new_clusters = new_clusters+2; %we do this so the unclustered data is treated as a cluster and we can eval clusters
            sihlouette_after = evalclusters(current_clustering_data,'gmdistribution',"silhouette","KList",2:5,"ClusterPriors","equal");
            
            new_clusters = sihlouette_after.OptimalY;
            davies_after = evalclusters(current_clustering_data,new_clusters,"DaviesBouldin");
            calinski_after = evalclusters(current_clustering_data,new_clusters,"CalinskiHarabasz");
           

            fprintf("Silhouette with k = %i %.2f\n",sihlouette_after.OptimalK,max(sihlouette_after.CriterionValues));
            unique_clusters = unique(new_clusters);
            new_cluster_idx = cell(length(unique_clusters),1);
            new_cluster_ts = cell(length(unique_clusters),1);
            for k=1:length(unique_clusters)
                old_cluster_ts = current_bp_table{j,"timestamps"}{1};
                old_cluster_idx = current_bp_table{j,"cluster_idx"}{1};
                new_cluster_ts{k} = old_cluster_ts(new_clusters==unique_clusters(k));
                new_cluster_idx{k} = old_cluster_idx(new_clusters==unique_clusters(k));
                cluster_addition = cluster_addition+1;
            end

            new_sil = repelem(max(sihlouette_after.CriterionValues),length(unique_clusters),1);
            new_dav = repelem(davies_after.CriterionValues,length(unique_clusters),1);
            new_cal = repelem(calinski_after.CriterionValues,length(unique_clusters),1);
            local_channels = repmat({[blind_pass_table{i,"rep_channel_1"},current_alternate_channel]},length(unique_clusters),1);
            new_table = table(repelem(current_z_score,length(unique_clusters),1), ...
                repelem(current_tetrode,length(unique_clusters),1), ...
                unique_clusters,...
                new_cluster_ts,...
                new_cluster_idx,...
                local_channels,...
                new_sil,...
                new_dav,...
                new_cal,...
                'VariableNames', ...
                ["Z Score","Tetrode","Cluster","timestamps","cluster_idx","channels","sil_score","davies_score","calinski_score"]);

            if config.has_ground_truth && config.debug_with_ground_truth

                new_table_with_accuracy = add_overlap_percentage_col_and_max_overlap_unit_optimized(new_table,config,timestamps);
                new_table_with_accuracy = add_accuracy_col(config,new_table_with_accuracy);
                cell_array_of_new_tables_for_each_channel{c} = new_table_with_accuracy;
            else
                cell_array_of_new_tables_for_each_channel{c} = new_table;
            end


            % fprintf("Finished %i / %i for bp row %i\n",j,length(current_comparison_peaks_for_current_aligned),i);
        end
        cell_array_of_new_tables_for_each_clust{j} = vertcat(cell_array_of_new_tables_for_each_channel);
    end

    cell_array_of_new_tables{i} = cell_array_of_new_tables_for_each_clust;

end

end