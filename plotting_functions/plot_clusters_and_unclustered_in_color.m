function [sampled_peaks] =  plot_clusters_and_unclustered_in_color(cluster_filters, aligned, x_axis, y_axis,channels,z_score,plot_counter,sample,sampled_peaks)
channel_string = "";
for j=1:size(channels,2)
    channel_string = channel_string + " C"+string(channels(j));
end

if sample
    rng(0)
    if nargin == 8
        sampled_peaks = cell(size(cluster_filters,1)+1,1);
    end
end
data = get_peaks(aligned, true)';
colors = distinguishable_colors(length(cluster_filters)*3);
my_gray = [0.5 0.5 0.5];
myplot = @(x, y, c, m, s) plot(x, y, 'Color', c, 'LineStyle', 'none', 'Marker', m, 'MarkerSize', s,'MarkerFaceColor',c,'MarkerEdgeColor',c);

hold on
legend_string = [];

in_cluster = [];
for c = 1:length(cluster_filters)
    peaks_in_cluster = cluster_filters{c};
    if isempty(peaks_in_cluster)
        continue;
    end
    in_cluster = union(in_cluster,peaks_in_cluster);

    if size(peaks_in_cluster,1) > 1000 && sample 
        if isempty(sampled_peaks{c})
            random_indexes = randi(size(peaks_in_cluster,1),100,1);
            sampled_peaks{c} = random_indexes;
        else
            random_indexes = sampled_peaks{c};
        end
        peaks_in_cluster = peaks_in_cluster(random_indexes,:);
    end

    
    peaks_in_cluster(peaks_in_cluster > size(aligned,2)) = [];
    cluster = data(peaks_in_cluster, :);
    cluster_x = cluster(:, x_axis);
    cluster_y = cluster(:, y_axis);
    myplot(cluster_x, cluster_y, colors(c,:), 'o', 2)

    legend_string =[legend_string, "cluster "+string(c)];
    hold on;
end

unclustered_rows = setdiff(1:size(data,1),in_cluster);
if size(unclustered_rows,2)>1000 && sample
    if isempty(sampled_peaks{end})
        random_indexes = randi(size(unclustered_rows,2),100,1);
        unclustered_rows = unclustered_rows(:,random_indexes);
        sampled_peaks{end} = unclustered_rows;
    else
        unclustered_rows = sampled_peaks{end};
    end
    
    
end
hold on;

myplot(data(unclustered_rows, x_axis), data(unclustered_rows, y_axis), my_gray, 'o', 2)
already_plotted = union(unclustered_rows,in_cluster);
xticks([min(data(already_plotted,x_axis)),max(data(already_plotted,x_axis))]);
yticks([min(data(already_plotted,y_axis)),max(data(already_plotted,y_axis))]);
legend_string = [legend_string,"Unclustered"];
xlabel(sprintf('Dim %d Peaks', channels(x_axis)))
ylabel(sprintf('Dim %d Peaks', channels(y_axis)))
title(string(z_score));
if plot_counter==1
    legend(legend_string,'Location','best');
end
hold off
end