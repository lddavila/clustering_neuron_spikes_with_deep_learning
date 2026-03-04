%edited by Luis David Davila and Alexander Friedman
function the_idx = get_idx_from_timestamps(the_timestamps, the_cluster_timestamps)
%GET_IDX_FROM_TIMESTAMP Gets the indices in 'timestamps' for the closest
%timestamps found in 'cluster_timestamps.' Times are in seconds.
    the_idx = nan(size(the_cluster_timestamps));
    [~, bin] = histc(the_cluster_timestamps, the_timestamps);
    for k = 1:length(the_cluster_timestamps)
        spike_idx = bin(k);
        if spike_idx == 0
            range = [1, length(the_timestamps)];
        else
            range = spike_idx:min(length(the_timestamps), spike_idx + 1);
        end
        [difference, range_idx] = min(abs(the_timestamps(range) - the_cluster_timestamps(k)));
        if difference >= 1e-3 % 1 millisecond
            continue
        end
        the_idx(k) = range(range_idx);
    end
    the_idx = the_idx(~isnan(the_idx));
end
