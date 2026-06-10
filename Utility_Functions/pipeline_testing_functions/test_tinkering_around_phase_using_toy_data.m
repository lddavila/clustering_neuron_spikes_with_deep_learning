function [] = test_tinkering_around_phase_using_toy_data(toy_data,ground_truth_idxs,ground_truth_cores,config,all_wf)
%create tetrodes from the toy data dimensions
config.ART_TETR_ARRAY = reshape(1:size(toy_data,2),[],4);
clusters_for_toy_data = cell(size(config.ART_TETR_ARRAY,1),1);
for i=1:size(config.ART_TETR_ARRAY,1)
    current_peaks = toy_data(:,config.ART_TETR_ARRAY(i,:)); %get the peaks for the current tetrode
    current_waveforms = reshape(all_wf(:,:,config.ART_TETR_ARRAY(i,:)),length(config.ART_TETR_ARRAY(i,:)),size(current_peaks,1),size(all_wf,2));
    %of these dimensions check how many clusters appear on them
    number_of_clusters = 0;
    current_waveforms = align_to_peak_ver_2(current_waveforms);
    for j=1:length(ground_truth_cores)
        if sum(ismember(config.ART_TETR_ARRAY(i,:),ground_truth_cores{j})) >=2
            number_of_clusters = number_of_clusters+1;
        end
    end
    fprintf("# of clusters that appear on this tetrode %i\n",number_of_clusters);
    fprintf("# of clusters found by dbscan: %i\n",length(unique(clusters_for_toy_data{i}))-1)
    

    current_peaks = toy_data(:,config.ART_TETR_ARRAY(i,:));
    z_sc_of_peaks = zscore(max(current_peaks, [], 2));
    the_percentiles = prctile(z_sc_of_peaks,1:100);
    
    snr_threshs = the_percentiles(config.percentiles_to_use);
    the_subsets = cell(1,length(snr_threshs));
    for j=1:length(snr_threshs)-1
        the_subsets{j} = z_sc_of_peaks > snr_threshs;
    end
    the_subsets{end} = ones(size(current_peaks,1),1);
    %we're just using percentiles of z score here not the full pmv, it's just approximated
    clusters_for_toy_data{i} = get_clusters_for_toy_data(current_peaks,the_subsets,current_waveforms,config.spikesort,config);
    
    
end
end