function [avg_tightness_of_cluster] = calculate_tightness_of_waveform_per_cluster(mean_waveform_for_cluster_k,spikes,debug)
%first step is to chop of the first 20% and last 20% of data pts or so in
%order to eliminate the beginning and end of the spike
avg_tightness_of_cluster = NaN;
number_of_data_points_to_cut = round(length(mean_waveform_for_cluster_k) * .20);
mean_waveform_for_cluster_k =mean_waveform_for_cluster_k(number_of_data_points_to_cut:end-number_of_data_points_to_cut*1.5);


euc_dist_between_spikes_and_mean_waveform = zeros(size(spikes,2),size(spikes,1));
for spike_counter =1:size(spikes,2)
    for wire_counter=1:size(spikes,1)
        current_spike = squeeze(spikes(wire_counter,spike_counter,:)).';
        current_spike = current_spike(number_of_data_points_to_cut:end - number_of_data_points_to_cut*1.5);
        euc_dist_vector= current_spike - mean_waveform_for_cluster_k;
        euc_dist_between_spikes_and_mean_waveform(spike_counter,wire_counter) = sqrt(euc_dist_vector*euc_dist_vector.');
    end
end

if debug
    figure;
    plot(1:length(mean_waveform_for_cluster_k),mean_waveform_for_cluster_k)
    figure
    histogram(reshape(euc_dist_between_spikes_and_mean_waveform,1,[]))
end

avg_tightness_of_cluster = median(euc_dist_between_spikes_and_mean_waveform,"all") / max(euc_dist_between_spikes_and_mean_waveform,[],"all");
end