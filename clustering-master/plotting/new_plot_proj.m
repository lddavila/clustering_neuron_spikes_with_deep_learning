%edited by Luis David Davila and Alexander Friedman
function new_plot_proj(the_cluster_filters, the_aligned, the_x_axis, the_y_axis,the_channels,the_current_tetrode)
channel_string = "";
for j=1:size(the_channels,2)
    channel_string = channel_string + " C"+string(the_channels(j));
end




data = get_peaks(the_aligned, true)';

color_mat = load('colors.mat');
colors = color_mat.colors;
colors = distinguishable_colors(length(the_cluster_filters)+10);
my_gray = [0.5 0.5 0.5];
myplot = @(x, y, c, m, s) plot(x, y, 'Color', c, 'LineStyle', 'none', 'Marker', m, 'MarkerSize', s,'MarkerFaceColor',c,'MarkerEdgeColor',c);

figure
% set(gcf, 'Visible', 'off')
  % set(gca, 'Color', 'k')
hold on
legend_string = cell(1,length(the_cluster_filters)+1);
myplot(data(:, the_x_axis), data(:, the_y_axis), my_gray, 'o', 2)
legend_string{1} = "Unclustered";
for c = 1:length(the_cluster_filters)
    peaks_in_cluster = the_cluster_filters{c}; 
    peaks_in_cluster(peaks_in_cluster > size(the_aligned,2)) = [];
    cluster = data(peaks_in_cluster, :);
    cluster_x = cluster(:, the_x_axis);
    cluster_y = cluster(:, the_y_axis);
    myplot(cluster_x, cluster_y, colors(c,:), 'o', 2)
    legend_string{c+1} = "c"+string(c);
    % hold on;
end
xlabel(sprintf('Channel %d Peaks', the_channels(the_x_axis)))
ylabel(sprintf('Channel %d Peaks', the_channels(the_y_axis)))
title([the_current_tetrode,channel_string,"# of Total Spikes:"+string(size(the_aligned,2))]);
legend(legend_string,'Location','best');
hold off
%     set(gca, 'TickDir', 'out')
% set(gca, 'box', 'off')
% set(gca, 'xticklabel', [])
% set(gca, 'yticklabel', [])
% set(gcf, 'Visible', 'on')
% set(gcf, 'InvertHardCopy', 'off')
end