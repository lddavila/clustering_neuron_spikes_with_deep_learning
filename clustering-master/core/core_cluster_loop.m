%this file has been edited by Luis D. Davila and Alexander Friedman 
function [the_final_clusters,full_config ]= core_cluster_loop(the_spike_aligned, the_extract_features_fn, the_new_config,the_peak_pcs_file_name,full_config)
    level = 1; %start the level
    done = false; %by default you are not done
    start_cl = struct(); %create a starting cluster struct object
    start_cl.subclust = true; %set the subcluster property of the starting cluster equal to true
    start_cl.idx = 1:size(the_spike_aligned, 2); % put all spikes in spike_aligned into the initial cluster 
    clusters = {start_cl}; %the initial clusters to be subclustered is just the starting cluster object
    while ~done && level <= the_new_config.MAX_SUBCLUSTER_DEPTH % by default this is 5
        % disp("entered while core_cluster_loop.m ")
        full_config.current_level = level;
        if level == 1
            cluster_ns = the_new_config.CLUSTER_NS; %default value is 6
        else
            cluster_ns = the_new_config.SUBCLUSTER_NS; %default subcluster number is 4
        end
        next_clusters = {}; %will store each pass of clusters found by core_cluster
        done = true; %for stopping purposes 
        for k = 1:length(clusters) %on first pass takes the entire data set as a cluster
            cl = clusters{k}; %take cluster k from the data set
            if cl.subclust %check if cl should be sub clustered again 
                done = false; %make sure the algorithm doesn't stop because the current cluster needs to be subclustered again
                [subclusters,full_config]= core_cluster(the_spike_aligned(:, cl.idx, :), cluster_ns, cl.idx, the_extract_features_fn, the_new_config,the_peak_pcs_file_name,full_config); %get back subclusters from initial clutster
                next_clusters = [next_clusters subclusters]; %add new subclusters to the list of clusters

            else
                next_clusters = [next_clusters cl]; %if cl doesn't/can't be subclustered then just add it back to the next_clusters list as it is "completed"
            end

        end
        clusters = next_clusters; %overwrite the clusters you began with
        %this is important because it ensures that you will continue to subcluster the clusters which are still subclusterable, and not keep reclustering the same clusters again and again
        % config,aligned,cluster_idx_struct,which_subset
        % disp("about to create_Cluster_plots_with_accuracy_while_clustering_and_sub_clu")
        if full_config.has_ground_truth && full_config.debug_with_ground_truth
            create_cluster_plots_with_accuracy_while_clustering_and_sub_clu(full_config,the_spike_aligned,next_clusters,string(level))
            full_config.plot_counter = full_config.plot_counter+1;
        end
        % disp("Finished creating the plot")
        level = level + 1; %increase the subcluster level
        % close all;
    end
    % disp("finished and exited the core cluster while loop")
    the_final_clusters = cellmap(@(x) x.idx, clusters); %returns the result of all subclustering
    %result is a 1xnumber_of_clusters cell array where each item is the index of the spikes located in the kth cluster
end