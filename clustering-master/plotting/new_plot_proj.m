function new_plot_proj(cluster_filters, aligned, x_axis, y_axis,channels,current_tetrode)
channel_string = "";
for j=1:size(channels,2)
    channel_string = channel_string + " C"+string(channels(j));
end




data = get_peaks(aligned, true)';

color_mat = load('colors.mat');
colors = color_mat.colors;
colors = distinguishable_colors(length(cluster_filters)+10);
my_gray = [0.5 0.5 0.5];
myplot = @(x, y, c, m, s) plot(x, y, 'Color', c, 'LineStyle', 'none', 'Marker', m, 'MarkerSize', s,'MarkerFaceColor',c,'MarkerEdgeColor',c);

figure
% set(gcf, 'Visible', 'off')
  % set(gca, 'Color', 'k')
hold on
legend_string = cell(1,length(cluster_filters)+1);
myplot(data(:, x_axis), data(:, y_axis), my_gray, 'o', 2)
legend_string{1} = "Unclustered";
for c = 1:length(cluster_filters)
    peaks_in_cluster = cluster_filters{c}; 
    peaks_in_cluster(peaks_in_cluster > size(aligned,2)) = [];
    cluster = data(peaks_in_cluster, :);
    cluster_x = cluster(:, x_axis);
    cluster_y = cluster(:, y_axis);
    myplot(cluster_x, cluster_y, colors(c,:), 'o', 2)
    legend_string{c+1} = "c"+string(c);
    % hold on;
end
xlabel(sprintf('Channel %d Peaks', channels(x_axis)))
ylabel(sprintf('Channel %d Peaks', channels(y_axis)))
title([current_tetrode,channel_string,"# of Total Spikes:"+string(size(aligned,2))]);
legend(legend_string,'Location','best');
hold off
%     set(gca, 'TickDir', 'out')
% set(gca, 'box', 'off')
% set(gca, 'xticklabel', [])
% set(gca, 'yticklabel', [])
% set(gcf, 'Visible', 'on')
% set(gcf, 'InvertHardCopy', 'off')
end