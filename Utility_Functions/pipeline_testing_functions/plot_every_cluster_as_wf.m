function [] = plot_every_cluster_as_wf(aligned,cluster_filter,dir_to_save_figs)

colors = distinguishable_colors(length(cluster_filter));
f = figure;
tiledlayout(2,2)
for j=1:size(aligned,1)

    legend_string = repelem("",length(colors),1);
    nexttile();
    for i=1:length(cluster_filter)

        plot(squeeze(aligned(j,cluster_filter{i},:)).','Color',colors(i,:));
        legend_string(i) = "cluster "+string(i);
        hold on;
    end



end
legend(legend_string)
close all;
end