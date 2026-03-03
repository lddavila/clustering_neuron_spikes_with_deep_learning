%updated by Luis David Davila and Alexander Friedman
function run_cluster_comparison_statistic(the_aligned_wf, the_tvals, the_timestamps, the_output, the_manual_output, the_stat_filename, the_config)
%RUN_CLUSTER_COMPARISON_STATISTIC Compares algorithm's output to manually
%clustered output, and saves the result to a file.
%   RUN_CLUSTER_COMPARISON_STATISTIC(aligned, tvals, timestamps, output,
%   manual_output, stat_filename)
%
%   'aligned' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%   It is the same as 'raw', but with spikes aligned to have the same peak
%   index.
%
%   'tvals' are the threshold values for each wire in microvolts.
%
%   'timestamps' are the timestamps for each spike in microseconds.
%
%   'output' is the output of the algorithm.
%   'manual_output' is the output of the manual clustering.
%   Both of them have two columns:
%   - the first column has the timestamp of each spike
%   - the second column has the cluster number of each spike
%
%   'stat_filename' is the filename to which to save the results.

    ts_seconds = the_timestamps / 1e6;
    peaks = get_peaks(the_aligned_wf, true)';
    if isempty(the_output)
        cf = {};
    else
        cf = extract_clusters_from_output(ts_seconds, the_output, the_config.spikesort);
    end
    cf_manual = extract_clusters_from_output(ts_seconds, the_manual_output, the_config.spikesort);
    found = false(size(cf_manual));
    stat = nan(length(cf_manual), length(cf));
    for c1 = 1:length(cf)
        cluster1 = cf{c1};
        wire_filter1 = find_singular_cols(peaks(cluster1, :));
        for c2 = 1:length(cf_manual)
            cluster2 = cf_manual{c2};
            wire_filter2 = find_singular_cols(peaks(cluster2, :));
            wire_filter = wire_filter1 & wire_filter2;
            stat(c2, c1) = bhat_dist(peaks(cluster1, wire_filter), peaks(cluster2, wire_filter));
            if stat(c2, c1) < 1
                found(c2) = true;
            end
        end
    end
    clusters_found = find(found);
    manual_gradings = compute_gradings_ver_2(the_aligned_wf, the_timestamps, the_tvals, cf_manual, the_config.spikesort);
    save_stat(the_stat_filename, stat, clusters_found, manual_gradings);
end