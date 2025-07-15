function [mean_z_score] = calculate_avg_z_score_per_channel(aligned,peaks_in_cluster)

mean_z_score = zeros(1,size(aligned,1)) ./ NaN;
data = get_peaks(aligned, true)';
cluster = data(peaks_in_cluster, :);

for i=1:size(aligned,1)
    cluster_x = cluster(:, i);
    mean_z_score(i) = mean(zscore(cluster_x));
end



end