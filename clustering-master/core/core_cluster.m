function clusters = core_cluster(spikes, cluster_ns, cluster_idx_inj, extract_features_fn, config)
%spikes : 
%   An array with the following dimensions:
%   number_of_channels X number_of_spikes X number_of_data_points matrix
%cluster_n : 
%   an int representing how many cluster configurations hsould be tried, will try 1:n clusters for ideal value
%cluster_idx_inj: 
%   the indexes of all spikes in the current cluster
%extract_features_function:
%   the function called cluster_prepare_data.m, which may be subject to change
%config:
%   the default config file


%CLUSTER Performs the actual clustering and subclustering (as well as
%feature extraction and selection)
% cluster_idx_inj: all the indexes for every spike
    
    [n, U] = cluster_prepare_data(spikes, cluster_ns, extract_features_fn, config);
    if n == 0 %means no clusters were found 
        clusters = {}; 
    elseif n == 1 %means only a single cluster was found
        cl = struct(); %creates a cluster object to be used
        cl.subclust = false; %set the subclustering parameter of the cluster object to false, ensuring it won't be subclustered again
        cl.idx = cluster_idx_inj; % puts all of the current spikes under the current spike object
        clusters = {cl}; %sets the return parameter to be only the current cluster object
    else
        maxU = max(U); %find the max U-coeffecient for every spike in the data
        base_cluster_filters = repmat(maxU, [n, 1]) == U; %matrix which tells you which cluster each spike belongs to 
        clusters = {}; %will be used to keep track of all the clusters which will be returned 
        for k = 1:n %cycles through all the clusters
            cluster_filter = base_cluster_filters(k, :); %get all the spikes in cluster k
            subcluster_idx_inj = cluster_idx_inj(cluster_filter); %get all indexes of the spikes for the current cluster
            if length(subcluster_idx_inj) < config.params.CL_MIN_CLUSTER_SPIKES %indicates that the current cluster is too small to be significant
                continue
            end
            subcl = struct();
            subcl.subclust = ~isequal(cluster_idx_inj, subcluster_idx_inj); %is true if the current subcluster, does not encompass the entire parent cluster
            subcl.idx = subcluster_idx_inj; %all the spikes in the current cluster
            clusters = [clusters subcl]; %add the new cluster object to the list of clusters
%             cluster_spikes = spikes(:, cluster_filter, :);
%             subclusters = core_cluster(cluster_spikes, ...
%                             config.SUBCLUSTER_NS, ...
%                             config, ...
%                             subcluster_idx_inj, ...
%                             level + 1);
%             if ~isempty(subclusters)
%                 clusters = [clusters subclusters];
%             end
        end
    end
end
