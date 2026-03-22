function [] = plot_every_cluster_as_wf_individually(aligned,cluster_filter,config)
save_dir = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"pipeline_stages");
colors = distinguishable_colors(length(cluster_filter));

for i=1:length(cluster_filter)
    f = figure;
    tiledlayout(2,2)
    for j=1:size(aligned,1)
        nexttile();
        % legend_string = repelem("",length(colors),1);
        plot(squeeze(aligned(j,cluster_filter{i},:)).','Color',colors(i,:));
    end
    sgtitle("Cluster "+string(i) +" Size: "+string(length(cluster_filter{i})))
    save_plots_in_all_formats(f,fullfile(save_dir,"Cluster_"+string(i)))
    close(f);
end

% legend(legend_string)
close all;
end