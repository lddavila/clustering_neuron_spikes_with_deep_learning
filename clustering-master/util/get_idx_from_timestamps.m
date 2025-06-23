function idx = get_idx_from_timestamps(timestamps, cluster_timestamps)
%GET_IDX_FROM_TIMESTAMP Gets the indices in 'timestamps' for the closest
%timestamps found in 'cluster_timestamps.' Times are in seconds.
    idx = nan(size(cluster_timestamps));
    [~, bin] = histc(cluster_timestamps, timestamps);
    for k = 1:length(cluster_timestamps)
        spike_idx = bin(k);
        if spike_idx == 0
            range = [1, length(timestamps)];
        else
            range = spike_idx:min(length(timestamps), spike_idx + 1);
        end
        [difference, range_idx] = min(abs(timestamps(range) - cluster_timestamps(k)));
        if difference >= 1e-3 % 1 millisecond
            continue
        end
        idx(k) = range(range_idx);
    end
    idx = idx(~isnan(idx));
end
