function [] = plot_clusters_for_paper(table_of_clusters_to_plot,dir_to_save_figs_to,sample)
unique_cluster_fp = unique(table_of_clusters_to_plot{:,"dir_to_aligned"});
for i=1:size(unique_cluster_fp,1)
    current_rows = table_of_clusters_to_plot(table_of_clusters_to_plot{:,"dir_to_aligned"}==unique_cluster_fp(i),:);
    current_aligned = importdata(unique_cluster_fp(i));
    current_grades = current_rows{1,"grades"}{1};
    current_channels = current_grades{49};
    idx_array = current_rows{:,"cluster_idx"};
    name_of_tetrode = current_rows{1,"Tetrode"};
    current_z_score = current_rows{1,"Z Score"};
    plot_clusters_by_z_score(current_channels,idx_array,current_aligned,name_of_tetrode,current_z_score,dir_to_save_figs_to,sample);
end
end