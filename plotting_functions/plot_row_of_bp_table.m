function [] = plot_row_of_bp_table(bp_table_row)

f = figure;
number_of_permutations = nchoosek(1:length(bp_table_row{1,"channels"}),2);
aligned = load(bp_table_row{1,"fp_to_aligned"});
aligned = aligned.data_to_save;
aligned = aligned.aligned;
peaks = get_peaks(aligned,true);
tiledlayout(floor(sqrt(size(number_of_permutations,1))),ceil(sqrt(size(number_of_permutations,1))));
cluster_colors = distinguishable_colors(height(bp_table_row));
legend_string = repelem("",height(bp_table_row),1);
current_channels = bp_table_row{1,"channels"};
for i=1:size(number_of_permutations,1)
    nexttile;
    
    for j=1:height(bp_table_row)
        legend_string(j) = sprintf("Cluster %i",j);
        current_cluster_idxs = bp_table_row{j,"cluster_idx"}{1};
        scatter(peaks(number_of_permutations(i,1),current_cluster_idxs),peaks(number_of_permutations(i,2),current_cluster_idxs),1,cluster_colors(j,:),'filled');
        hold on;
    end
    if i==1
        legend(legend_string);
    end
    xlabel("Channel "+string(current_channels(number_of_permutations(i,1))) +" (in \muV)")
    ylabel("Channel "+string(current_channels(number_of_permutations(i,2))) +" (in \muV)")
    
end
title_string = "Clustering Results for Channel Group "+string(strrep(bp_table_row{1,"Tetrode"},"t",""))+" (Channels "+strjoin(string(current_channels))+" Assembled due to physical promxity) with Threshold Multiplier k="+string(bp_table_row{1,"Z Score"});
sgtitle(title_string)
close(f);
end