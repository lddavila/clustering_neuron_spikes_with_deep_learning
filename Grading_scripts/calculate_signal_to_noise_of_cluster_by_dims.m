function [snr_ratio] = calculate_signal_to_noise_of_cluster_by_dims(aligned,peaks_in_cluster,first_best_dim,sec_best_dim)

% all_snr = zeros(1,size(aligned,1)) ./ NaN;
data = get_peaks(aligned, true)';
inner_circle_n_of_std = 3;
outer_circle_n_of_std = 4;
% for i=1:size(aligned,1)


cluster = data(peaks_in_cluster, :);
cluster_x = cluster(:, first_best_dim);
cluster_y = cluster(:, sec_best_dim);

cluster_mean_x = mean(cluster_x);
cluster_std_x = std(cluster_x);

cluster_mean_y = mean(cluster_y);
cluster_std_y = std(cluster_y);


inner_rim_above_x = cluster_mean_x + (inner_circle_n_of_std*cluster_std_x);
inner_rim_below_x = cluster_mean_x - (inner_circle_n_of_std*cluster_std_x);
outer_rim_above_x = cluster_mean_x + (outer_circle_n_of_std * cluster_std_x);
outer_rim_below_x = cluster_mean_x - (outer_circle_n_of_std * cluster_std_x);

inner_rim_above_y = cluster_mean_y + (inner_circle_n_of_std*cluster_std_y);
inner_rim_below_y = cluster_mean_y - (inner_circle_n_of_std*cluster_std_y);
outer_rim_above_y = cluster_mean_y + (outer_circle_n_of_std * cluster_std_y);
outer_rim_below_y = cluster_mean_y - (outer_circle_n_of_std * cluster_std_y);


outside_inner_rim_x = (data(:,first_best_dim) > inner_rim_above_x & data(:,first_best_dim) <= outer_rim_above_x) | (data(:,first_best_dim) < inner_rim_below_x  & data(:,first_best_dim) > outer_rim_below_x);
outside_inner_rim_y = (data(:,sec_best_dim) > inner_rim_above_y & data(:,sec_best_dim) <= outer_rim_above_y) | (data(:,sec_best_dim) < inner_rim_below_y  & data(:,sec_best_dim) > outer_rim_below_y);

n_dpts_in_cluster = length(peaks_in_cluster);
n_dpts_in_outer_rim = sum(outside_inner_rim_x | outside_inner_rim_y);
%n_dpts_in_inner_rim = size(data( (data(:,i) <= inner_rim_above) & (data(:,i) >= inner_rim_below)  ,i),1) ;
snr_ratio = (n_dpts_in_cluster - n_dpts_in_outer_rim )/ (n_dpts_in_cluster + n_dpts_in_outer_rim);

% end

% snr_ratio = all_snr(which_dim);


end