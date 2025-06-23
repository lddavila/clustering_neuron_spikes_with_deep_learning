function final_clusters = core_cluster_loop(spike_aligned, extract_features_fn, config)
    level = 1; %start the level
    done = false; %by default you are not done
    start_cl = struct(); %create a starting cluster struct object
    start_cl.subclust = true; %set the subcluster property of the starting cluster equal to true
    start_cl.idx = 1:size(spike_aligned, 2); % put all spikes in spike_aligned into the initial cluster 
    clusters = {start_cl}; %the initial clusters to be subclustered is just the starting cluster object
    while ~done && level <= config.MAX_SUBCLUSTER_DEPTH % by default this is 5
        if level == 1
            cluster_ns = config.CLUSTER_NS; %default value is 6
        else
            cluster_ns = config.SUBCLUSTER_NS; %default subcluster number is 4
        end
        next_clusters = {}; %will store each pass of clusters found by core_cluster
        done = true; %for stopping purposes 
        for k = 1:length(clusters) %on first pass takes the entire data set as a cluster
            cl = clusters{k}; %take cluster k from the data set
            if cl.subclust %check if cl should be sub clustered again 
                done = false; %make sure the algorithm doesn't stop because the current cluster needs to be subclustered again 
                subclusters = core_cluster(spike_aligned(:, cl.idx, :), cluster_ns, cl.idx, extract_features_fn, config); %get back subclusters from initial clutster
                next_clusters = [next_clusters subclusters]; %add new subclusters to the list of clusters 

            else
                next_clusters = [next_clusters cl]; %if cl doesn't/can't be subclustered then just add it back to the next_clusters list as it is "completed"
            end
        end
        clusters = next_clusters; %overwrite the clusters you began with 
                                  %this is important because it ensures that you will continue to subcluster the clusters which are still subclusterable, and not keep reclustering the same clusters again and again
        
        level = level + 1; %increase the subcluster level
        % close all;
     end
    final_clusters = cellmap(@(x) x.idx, clusters); %returns the result of all subclustering
                                                    %result is a 1xnumber_of_clusters cell array where each item is the index of the spikes located in the kth cluster
end