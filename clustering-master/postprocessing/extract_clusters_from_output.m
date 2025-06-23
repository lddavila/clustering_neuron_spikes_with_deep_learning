function idx = extract_clusters_from_output(timestamps, output, config)
%EXTRACT_CLUSTERS_FROM_OUTPUT Converts the standard output format of spike
%sorting into a format that's easier to work with (a cell array of indices
%for each cluster).
%   idx = EXTRACT_CLUSTERS_FROM_OUTPUT(timestamps, output)
%
%   'timestamps' are the timestamps for each spike in seconds.
%
%   'output' is the standardized output format.
%   - the first column contains the timestamps of the spikes in seconds
%   - the second column contains the cluster classification of the spikes
%       E.g., a value of '3' means that the spike belongs to cluster 3.
%
%   'idx' is a cell array of indices for each cluster.

    ids = unique(output(:, 2));
    ids = sort(ids(ids > 0));
    idx = cell(length(ids), 1);
    for k = 1:length(ids)
        cluster_timestamps = output(output(:, 2) == ids(k), 1);
        idx{k} = get_idx_from_timestamps(timestamps, cluster_timestamps);
        % if length(idx{k}) < config.MIN_NUMBER_OF_SPIKES
        %     idx{k} = [];
        % end
    end
    idx = idx(~cellfun('isempty', idx));
end