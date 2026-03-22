function plot_gt_and_surrounding_data(ground_truth_data,channel_data,found_spikes,unfiltered_channel_data,number_of_dpts_to_plot)
for i=1:length(ground_truth_data)
    f = figure;
    tiledlayout(1,2)
    nexttile();
    current_ground_truth_idxs = ground_truth_data(i);
    start_of_window = current_ground_truth_idxs - number_of_dpts_to_plot;
    end_of_window = current_ground_truth_idxs+number_of_dpts_to_plot;
    x_data = start_of_window:1:end_of_window;
    plot(x_data,channel_data(x_data).');
    hold on;
    scatter(current_ground_truth_idxs,channel_data(current_ground_truth_idxs),60,'red','filled');

    found_spikes_in_bound = start_of_window <= found_spikes & found_spikes <= end_of_window;
    scatter(found_spikes(found_spikes_in_bound), channel_data(found_spikes(found_spikes_in_bound)),'black','filled');
    legend("Filtered Data","Ground Truth","Detected Spikes")
    title("Filtered Data");

    % f_2 = figure;
    nexttile();
    plot(x_data,unfiltered_channel_data(x_data));
    hold on;
    scatter(current_ground_truth_idxs,unfiltered_channel_data(current_ground_truth_idxs),60,'red','filled');

    found_spikes_in_bound = start_of_window <= found_spikes & found_spikes <= end_of_window;
    scatter(found_spikes(found_spikes_in_bound), unfiltered_channel_data(found_spikes(found_spikes_in_bound)),'black','filled');
    legend("Unfiltered Data","Ground Truth","Detected Spikes")
    title("Unfiltered data")
    close(f);
    % close(f_2)
end
end