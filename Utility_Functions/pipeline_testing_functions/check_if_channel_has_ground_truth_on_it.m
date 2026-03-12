function [] = check_if_channel_has_ground_truth_on_it(ground_truth_data,channel_data,found_spikes,number_of_plots_to_split_into)

%we will use this function to determine whether or not the channel has
%spikes at the expected indexes according to ground truth data

how_many_data_pts_in_each_section = round(length(channel_data) / number_of_plots_to_split_into);
for i=1:number_of_plots_to_split_into
    f = figure();
    start_window = ((i-1)*how_many_data_pts_in_each_section )+1;
    end_of_window = min([(i*how_many_data_pts_in_each_section),length(channel_data)]);
    x_data = start_window:1:end_of_window;
    plot(x_data,channel_data(start_window:end_of_window));
    hold on;
    gt_in_bound = start_window <= ground_truth_data & ground_truth_data <= end_of_window;
    try
        xline(ground_truth_data(gt_in_bound));
    catch
    end
    found_spikes_in_bound = start_window <= found_spikes & found_spikes <= end_of_window;
    try
        xline(found_spikes(found_spikes_in_bound).','--r');

        % close(f);
    catch
    end
    legend("Channel Data","Ground Truth", "Detected Spikes")
    try
        close(f);
    catch
    end

end
end