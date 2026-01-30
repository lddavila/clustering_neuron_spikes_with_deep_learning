function [] = plot_channel_noise_data_struct(rec_ch_data_struct,how_many_units_to_plot,recording_name)
%create a struct to save this data to avoid repitition
%rec_ch_data_struct is produced by find_threshold_computationally and has the following fields
% "ironclust_ratios"
% "ironclust_noise_ratio"
% "ironclust_raw_unit_numbers"
% "ironclust_raw_noise_numbers"
raw_channel_count = rec_ch_data_struct.("ironclust_noise_ratio");
raw_noise_count = rec_ch_data_struct.("ironclust_ratios");

threshold_data = rec_ch_data_struct.("default_thresholds");

figure;
yyaxis left
plot(threshold_data(:,1),raw_channel_count(1:how_many_units_to_plot,:))
ylabel("Signal Ratio")
ylim([0,1])

yyaxis right
plot(threshold_data(:,1),raw_noise_count(1:how_many_units_to_plot,:))
ylabel("Noise Ratio")
% ylim([0,1])
title(recording_name+ " Iron Clust Spike Detection")
end