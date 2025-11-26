function [cell_array_of_images] = get_image_to_group_clusters(blind_pass_table,comparisons,config)
%cycle through all comparisons
cell_array_of_images = cell(size(comparisons,1),1);
%first update the blind pass data fpths to match the local machine
blind_pass_table = update_fpths(blind_pass_table,config);

%get a graph which will be used for calculating which waveforms should be
%plotted together
[G,~,~] = get_graph_rep_of_probe_map();


for i=1:size(comparisons,1)

    cluster_1_idx = comparisons(i,1);
    cluster_2_idx = comparisons(i,2);

    %get the file path to the actual spike data
    cluster_1_spikes_fp = blind_pass_table{cluster_1_idx,"fp_to_aligned"};
    cluster_2_spikes_fp = blind_pass_table{cluster_2_idx,"fp_to_aligned"};

    %get the cluster indexes
    cluster_1_spike_idx = importdata(blind_pass_table{cluster_1_idx,"fp_to_cleaned_clusters"});
    cluster_1_spike_idx = cluster_1_spike_idx.cleaned_clusters;
    cluster_1_spike_idx = cluster_1_spike_idx{blind_pass_table{cluster_1_idx,"Cluster"}};

    cluster_2_spike_idx = importdata(blind_pass_table{cluster_2_idx,"fp_to_cleaned_clusters"});
    cluster_2_spike_idx = cluster_2_spike_idx.cleaned_clusters;
    cluster_2_spike_idx = cluster_2_spike_idx{blind_pass_table{cluster_2_idx,"Cluster"}};

    %get the waveforms of each cluster
    cluster_1_waveforms = importdata(cluster_1_spikes_fp);
    cluster_1_waveforms = cluster_1_waveforms.aligned;
    cluster_1_waveforms = cluster_1_waveforms(:,cluster_1_spike_idx,:);

    cluster_2_waveforms = importdata(cluster_2_spikes_fp);
    cluster_2_waveforms = cluster_2_waveforms.aligned;
    cluster_2_waveforms = cluster_2_waveforms(:,cluster_2_spike_idx,:);

 

    %get the channels that make up cluster 2
    cluster_1_grades = blind_pass_table{comparisons(i,1),"grades"}{1};
    cluster_1_channels = cluster_1_grades{49};
    %get the channels that make up cluster 2
    cluster_2_grades = blind_pass_table{comparisons(i,2),"grades"}{1};
    cluster_2_channels = cluster_2_grades{49};

    %get the shortest distance between all probes
    % array_of_distances = zeros(max([length(cluster_1_channels),length(cluster_2_channels)]));
    % for j=1:length(cluster_1_channels)
    %     channel_1 = cluster_1_channels(j);
    %     for k=1:length(cluster_2_channels)
    %         channel_2 = cluster_2_channels(k);
    %         [~,array_of_distances(j,k)] = shortestpath(G,channel_1,channel_2);
    %     end
    % end


    % num_rows = max([length(cluster_1_channels),cluster_2_channels]);
    figure;
    tiledlayout(2,2);

    cluster_2_channels_temp = cluster_2_channels;
    cluster_1_channels_temp = cluster_1_channels;

    %plot the channels in common spikes first
    in_both = intersect(cluster_2_channels,cluster_1_channels);

    for j=1:length(in_both)
        nexttile();
        loc_of_ch_in_first_cluster = in_both(j)==cluster_1_channels;
        loc_of_ch_in_sec_cluster = in_both(j)==cluster_2_channels;
        cluster_1_waveforms_temp = squeeze(cluster_1_waveforms(loc_of_ch_in_first_cluster,:,:));
        cluster_2_waveforms_temp = squeeze(cluster_2_waveforms(loc_of_ch_in_sec_cluster,:,:));

        %randomly sample AT MOST 100 waveforms from each data set to be
        %plotted
        randomly_sampled_c1_wf_idxs = randperm(size(cluster_1_waveforms_temp,1),min([100,size(cluster_1_waveforms_temp,1)]));
        randomly_sampled_c2_wf_idxs = randperm(size(cluster_2_waveforms_temp,1),min([100,size(cluster_2_waveforms_temp,1)]));

        cluster_1_waveforms_temp = cluster_1_waveforms_temp(randomly_sampled_c1_wf_idxs,:);
        cluster_2_waveforms_temp = cluster_2_waveforms_temp(randomly_sampled_c2_wf_idxs,:);
        

        plot(cluster_1_waveforms_temp.','y','LineWidth',.1);
        hold on;
        plot(cluster_2_waveforms_temp.','m','LineWidth',.1);
        title(sprintf("Cluster 1 channel: %i Cluster 2 channel %i",in_both(j),in_both(j)))

    end


    remaining_cluster_1_channels = setdiff(cluster_1_channels_temp,in_both);
    remaining_cluster_2_channels = setdiff(cluster_2_channels_temp,in_both);
    for j=1:length(remaining_cluster_1_channels)
        nexttile();
        first_channel = remaining_cluster_1_channels(j);

        all_distances = zeros(length(remaining_cluster_2_channels),1);
        for k=1:length(all_distances)
            [~,all_distances(k)] = shortestpath(G,first_channel,remaining_cluster_2_channels(k));
        end

        [~,idx_of_min] = min(all_distances);
         
        %if there are 2 that are equal then just take the first
        idx_of_min = idx_of_min(1);

        %now get the second channel
        second_channel = remaining_cluster_2_channels(idx_of_min);


        %plot against the nearest other channel
        loc_of_ch_in_first_cluster = first_channel==cluster_1_channels;
        loc_of_ch_in_sec_cluster = second_channel==cluster_2_channels;
        cluster_1_waveforms_temp = squeeze(cluster_1_waveforms(loc_of_ch_in_first_cluster,:,:));
        cluster_2_waveforms_temp = squeeze(cluster_2_waveforms(loc_of_ch_in_sec_cluster,:,:));

        %randomly sample AT MOST 100 waveforms from each data set to be
        %plotted
        randomly_sampled_c1_wf_idxs = randperm(size(cluster_1_waveforms_temp,1),min([100,size(cluster_1_waveforms_temp,1)]));
        randomly_sampled_c2_wf_idxs = randperm(size(cluster_2_waveforms_temp,1),min([100,size(cluster_2_waveforms_temp,1)]));

        cluster_1_waveforms_temp = cluster_1_waveforms_temp(randomly_sampled_c1_wf_idxs,:);
        cluster_2_waveforms_temp = cluster_2_waveforms_temp(randomly_sampled_c2_wf_idxs,:);


        plot(cluster_1_waveforms_temp.','y','LineWidth',.1);
       
        hold on;
        plot(cluster_2_waveforms_temp.','m','LineWidth',.1);
        title(sprintf("Cluster 1 channel: %i Cluster 2 channel %i",first_channel,second_channel))
        remaining_cluster_2_channels = setdiff(remaining_cluster_2_channels,second_channel);



    end
    drawnow;
    cell_array_of_images{i} = getframe(gcf);
    close(gcf);
end
end