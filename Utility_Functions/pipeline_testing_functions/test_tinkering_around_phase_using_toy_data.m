function [] = test_tinkering_around_phase_using_toy_data(toy_data,ground_truth_idxs,ground_truth_cores,config)
%create tetrodes from the toy data dimensions
config.ART_TETR_ARRAY = reshape(1:100,[25,4]);
clusters_for_toy_data = cell(size(config.ART_TETR_ARRAY,1),1);
for i=1:size(config.ART_TETR_ARRAY,1)
    current_peaks = toy_data(:,config.ACG_THRESHOLD(i,:));
    z_sc_of_peaks = zscore(max(current_peaks, [], 2));
    snr_threshs = the_percentiles(config.percentiles_to_use);
    the_subsets = cell(1,length(snr_threshs));
    for j=1:length(snr_threshs)
        the_subsets{j} = snr
    end
    %we're just using percentiles of z score here not the full pmv, it's just approximated
    clusters_for_toy_data{i} = get_clusters_for_toy_data(the_subsets,current_peaks);
    
    
end
end