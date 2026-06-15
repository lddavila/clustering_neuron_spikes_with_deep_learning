function [the_clusters] = get_clusters_for_toy_data(peaks,the_subsets,the_aligned_spikes,the_config,full_config,the_ir,the_tvals)


the_clusters = {};
% peaks = get_peaks(the_aligned_spikes, true)';
total_num_spikes = size(the_aligned_spikes, 2);

num_std = the_config.params.IC_NUM_STD_REMOVE_CLUSTER;

bad = {};
%close all;
% disp("about to start the subsets loop")
the_peak_pcs_file_name = "";
for k = 1:length(the_subsets)
    filtered_idx = find(the_subsets{k});

    % For each cluster, remove its mean + num_std*std for each of the peak
    % dimensions.
    for c = 1:length(the_clusters)
        disp(c);
        cluster_idx = the_clusters{c};
        if length(cluster_idx)==1
            continue;
        end

        cp = peaks(cluster_idx, :);
        coeff = pca(cp);
        the_peak_pcs = nan(size(peaks, 1), min([size(the_aligned_spikes,1),2]));
        for p = 1:size(the_peak_pcs,2)
            the_peak_pcs(:, p) = peaks * coeff(:, p);
        end
        data = [peaks, the_peak_pcs];

        ints = true(total_num_spikes, 1);
        % close all;
        % plot_clusters_spike_refinement("Before Refinement",c,peaks,filtered_idx,4);
        %plot_aligned_for_refinment("Before Refinment",c,aligned,filtered_idx,4)
        for d = 1:size(data, 2) %cycle through the features
            feature = data(:, d);%index a feature column
            cluster_feature = feature(cluster_idx); %get the feature for the current cluster
            d_min = min(cluster_feature); %get the lower bound of the feature for the cluster
            d_max = max(cluster_feature); %get the uppre bound of the feature for the cluster

            d_mean = mean(cluster_feature); %get the mean of the feature for the cluster
            d_std = std(cluster_feature); %get the std of the mean of the feature for the cluster

            d_min = max(d_min, d_mean - num_std*d_std); %get the smallest value between the min cluster feature and the mean cluster feature - 3 * cluster featre_std
            d_max = min(d_max, d_mean + num_std*d_std); %get the max value between the max cluster feature and the mean cluster feature + 3 * cluster featre_std

            ints = ints & d_min < feature & feature < d_max; %check which cluster member's features lie between d_min and d_max
            %but the interesting part is that you check for this in between condition along every dimension of the cluster
            % therefore to pass for a cluster spike to survive the filter it must always be in between these values regardless of dimension
        end
        remove_spikes = union(find(ints), cluster_idx);
        filtered_idx = setdiff(filtered_idx, remove_spikes);
        %plot_clusters_spike_refinement("After Refinement",c,peaks,filtered_idx,4);
        %plot_aligned_for_refinment("After Refinment",c,aligned,filtered_idx,4)
    end

    % Run clustering with this pass of filtering as specified in
    % subsets, with everything removed above.
    the_refine_spike_idx = 1:1:size(the_aligned_spikes,2);
    full_config.which_subset = k;
    [cf, bad_tmp,full_config,is_bad_cluster] = run_clustering(the_aligned_spikes, filtered_idx, the_ir, the_tvals, the_refine_spike_idx, the_config,the_peak_pcs_file_name,full_config);
    all_cluster_sizes = cellfun(@length,cf);
    % if any(all_cluster_sizes>30000)
    %     disp("Cluster which will break produced")
    % end
    
    if the_config.DO_BAD_CLUSTER_ROUND && ~isempty(bad) %not sure why, but it will always skip the first time bad clusters are returned
        for c = 1:length(bad) %cycle through all the bad clusters
            cluster_idx = bad{c}; %get the idx for the bad clusters
            cp = peaks(cluster_idx, :); % get the peaks for the current bad cluster
            coeff = pca(cp); %get the pca coeff of the bad cluster peaks
            the_peak_pcs = nan(size(peaks, 1), min([size(the_aligned_spikes,1),2])); %create a matrix which is #-peaks by #-channels, presumably to be filled in
            for p = 1:size(the_peak_pcs,2) %cycle through the peak pcs matrix to fill in
                the_peak_pcs(:, p) = peaks * coeff(:, p); %fill in the matrix with the cluster peaks times the pca coeff
            end
            data = [peaks, the_peak_pcs]; % structure the data which will be reclustered

            ints = true(total_num_spikes, 1); %creates an array which seems to track which spikes pass the filtering test
            for d = 1:size(data, 2) %cycle through each of the clustering features
                feature = data(:, d); %get the current feature data
                cluster_feature = feature(cluster_idx); %get all the feature data that belonds to the current cluster
                d_min = min(cluster_feature); %get the min value of the cluster data
                d_max = max(cluster_feature); %get the max value for the cluster feature

                d_mean = mean(cluster_feature); %get the mean value of the cluster features
                d_std = std(cluster_feature); %get the std of the cluster features

                d_min = max(d_min, d_mean - num_std*d_std); %get the max value between the min cluster value and the cluster mean minus the config std (3 by default) * cluster std
                d_max = min(d_max, d_mean + num_std*d_std); %get the min value between hte max cluster value and the cluster mean plus the config std (3 by default) * cluster std

                ints = ints & d_min < feature & feature < d_max; %filter out any cluster features that don't fall between d_min and d_max
            end
            remove_spikes = union(find(ints), cluster_idx); %combine all the spikes that are in the bad cluster & the ones that don't pass the filter
            filtered_idx = setdiff(filtered_idx, remove_spikes); %remove those spikes from the spikes that we use for clustering
        end

        % Run clustering again with bad spikes removed
        [cf_bad,~,full_config,is_bad_cluster_for_bad_clusters]= run_clustering(the_aligned_spikes, filtered_idx, the_ir, the_tvals, the_refine_spike_idx, the_config,the_peak_pcs_file_name,full_config);
    else
        cf_bad = {};
    end

    % In case any of the new clusters overlap with the old ones, fix
    % overlaps.
    %the_clusters = fix_cluster_overlaps(the_aligned_spikes, [the_clusters, cf, cf_bad], the_config,full_config);
    if isempty(cf_bad)
        the_clusters = fix_cluster_overlaps(the_aligned_spikes, [the_clusters, cf(~is_bad_cluster),cf_bad], the_config,full_config);
    else
        the_clusters = fix_cluster_overlaps(the_aligned_spikes, [the_clusters, cf(~is_bad_cluster),cf_bad(~is_bad_cluster_for_bad_clusters)], the_config,full_config);
    end
    % disp("Length of Clusters" + string(length(clusters)));
    bad = bad_tmp;
    if full_config.has_ground_truth && full_config.debug_with_ground_truth
        create_cluster_plots_with_accuracy_while_clustering_and_sub_clu(full_config,the_aligned_spikes,the_clusters,full_config.which_thresh,"after_fix_cluster_overlaps");
        full_config.plot_counter = full_config.plot_counter +1;
    end
    % if ~isfile(full_config.base_aligned_sw_name)
    %     par_save(full_config.base_aligned_sw_name,full_config.mutated_spike_windows);
    % end
end

end