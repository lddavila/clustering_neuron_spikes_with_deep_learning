function [mean_z_score] = calculate_avg_z_score_per_channel_without_clust_filt(aligned)

mean_z_score = zeros(1,size(aligned,1)) ./ NaN;
data = get_peaks(aligned, true)';


for i=1:size(aligned,1)
    cluster_x = data(:, i);
    mean_z_score(i) = mean(zscore(cluster_x));
end



end