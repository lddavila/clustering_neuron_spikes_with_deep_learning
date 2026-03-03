%updated by Luis David Davila and Alexander Friedman
function [the_clusters,the_peak_pcs ]= iterative_clustering_ver_2(the_aligned_spikes, the_ir, the_tvals, the_refine_spike_idx, the_subsets, the_config,the_peak_pcs_file_name)
%version 2 returns the pcs AS WELL AS the clusters that the original
%returns
%ITERATIVE_CLUSTERING Performs several iterations/passes of the same clustering
%algorithm
%   clusters = ITERATIVE_CLUSTERING(aligned, ir, tvals, refine_spike_idx,
%   subsets, config) returns the final clusters.

    the_peak_pcs = nan;
    the_clusters = {};
    peaks = get_peaks(the_aligned_spikes, true)';
    total_num_spikes = size(the_aligned_spikes, 2);
    
    num_std = the_config.params.IC_NUM_STD_REMOVE_CLUSTER;
    
    bad = {};
    %close all;
    for k = 1:length(the_subsets)
        filtered_idx = the_subsets{k};
        
        % For each cluster, remove its mean + num_std*std for each of the peak
        % dimensions.
        for c = 1:length(the_clusters)
            cluster_idx = the_clusters{c};

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
            for d = 1:size(data, 2)
                feature = data(:, d);
                cluster_feature = feature(cluster_idx);
                d_min = min(cluster_feature);
                d_max = max(cluster_feature);

                d_mean = mean(cluster_feature);
                d_std = std(cluster_feature);

                d_min = max(d_min, d_mean - num_std*d_std);
                d_max = min(d_max, d_mean + num_std*d_std);

                ints = ints & d_min < feature & feature < d_max; %this is where stuff is being removed 
            end
            remove_spikes = union(find(ints), cluster_idx);
            filtered_idx = setdiff(filtered_idx, remove_spikes);
            %plot_clusters_spike_refinement("After Refinement",c,peaks,filtered_idx,4);
            %plot_aligned_for_refinment("After Refinment",c,aligned,filtered_idx,4)
        end
        
        % Run clustering with this pass of filtering as specified in
        % subsets, with everything removed above.
        [cf, bad_tmp] = run_clustering(the_aligned_spikes, filtered_idx, the_ir, the_tvals, the_refine_spike_idx, the_config,the_peak_pcs_file_name);
        
        if the_config.DO_BAD_CLUSTER_ROUND && ~isempty(bad)
            for c = 1:length(bad)
                cluster_idx = bad{c};
                cp = peaks(cluster_idx, :);
                coeff = pca(cp);
                the_peak_pcs = nan(size(peaks, 1), min([size(the_aligned_spikes,1),2]));
                for p = 1:size(the_peak_pcs,2)
                    the_peak_pcs(:, p) = peaks * coeff(:, p);
                end
                data = [peaks, the_peak_pcs];

                ints = true(total_num_spikes, 1);
                for d = 1:size(data, 2)
                    feature = data(:, d);
                    cluster_feature = feature(cluster_idx);
                    d_min = min(cluster_feature);
                    d_max = max(cluster_feature);

                    d_mean = mean(cluster_feature);
                    d_std = std(cluster_feature);

                    d_min = max(d_min, d_mean - num_std*d_std);
                    d_max = min(d_max, d_mean + num_std*d_std);

                    ints = ints & d_min < feature & feature < d_max;
                end
                remove_spikes = union(find(ints), cluster_idx);
                filtered_idx = setdiff(filtered_idx, remove_spikes);
            end

            % Run clustering again with bad clusters also removed.
            cf_bad = run_clustering(the_aligned_spikes, filtered_idx, the_ir, the_tvals, the_refine_spike_idx, the_config,the_peak_pcs_file_name);
        else
            cf_bad = {};
        end
        
        % In case any of the new clusters overlap with the old ones, fix
        % overlaps.
        the_clusters = fix_cluster_overlaps(the_aligned_spikes, [the_clusters, cf, cf_bad], the_config);
        % disp("Length of Clusters" + string(length(clusters)));
        bad = bad_tmp;
    end
end