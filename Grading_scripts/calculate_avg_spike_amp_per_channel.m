function [mean_spike_amp] = calculate_avg_spike_amp_per_channel(aligned,peaks_in_cluster)

mean_spike_amp = zeros(1,size(aligned,1)) ./ NaN;
data = get_peaks(aligned, true)';
cluster = data(peaks_in_cluster, :);

for i=1:size(aligned,1)
    cluster_x = cluster(:, i);
    mean_spike_amp(i) = mean(cluster_x);
end



end