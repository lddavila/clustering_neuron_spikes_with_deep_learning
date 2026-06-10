function [] = plot_clusters_by_z_score(channels_of_curr_tetr,idx,aligned,name_of_tetrode,current_z_score,dir_to_save_figs_to,sample)
%plot all the configurations of the clusters
figure('units','normalized','outerposition',[0 0 1 1]);
panel_counter = 1;
tiledlayout("flow");
for first_dimension = 1:length(channels_of_curr_tetr)
    for second_dimension = first_dimension+1:length(channels_of_curr_tetr)
        nexttile();
        if panel_counter==1
            sampled_peaks = plot_clusters_and_unclustered_in_color(idx,aligned,first_dimension,second_dimension,channels_of_curr_tetr,current_z_score,panel_counter,sample);
        else
            plot_clusters_and_unclustered_in_color(idx,aligned,first_dimension,second_dimension,channels_of_curr_tetr,current_z_score,panel_counter,sample,sampled_peaks);
        end
        panel_counter = panel_counter+1;
    end
end
sgtitle(name_of_tetrode+" Z Score:" + string(current_z_score))
set(gcf,'visible','on');
set(gcf, 'Renderer', 'painters');
saveas(gcf,fullfile(dir_to_save_figs_to,name_of_tetrode+" Z Score "+string(current_z_score)+" Cluster Plots.svg"));



end