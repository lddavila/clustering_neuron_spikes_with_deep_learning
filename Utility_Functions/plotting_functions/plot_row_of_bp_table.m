function [] = plot_row_of_bp_table(bp_table_row,varargin)

f = figure;
number_of_permutations = nchoosek(1:length(bp_table_row{1,"channels"}),2);
if isempty(varargin)
    aligned = load(bp_table_row{1,"fp_to_aligned"});
    aligned = aligned.data_to_save;
    aligned = aligned.aligned;
else
    aligned = varargin{1};
end

if length(varargin)==2
   %create_cluster_plots_with_accuracy_while_clustering_and_sub_clu(config,aligned,cluster_idx_struct,which_clustering_level,varargin)
    create_cluster_plots_with_accuracy_while_clustering_and_sub_clu(varargin{2},varargin{1},bp_table_row{1,"cluster_idx"},1,"");
    return;
end
peaks = get_peaks(aligned,true);
%tiledlayout(floor(sqrt(size(number_of_permutations,1))),ceil(sqrt(size(number_of_permutations,1))));
t = tiledlayout('flow');
cluster_colors = distinguishable_colors(height(bp_table_row));
legend_string = repelem("",height(bp_table_row),1);
current_channels = bp_table_row{1,"channels"};
% number_of_plots_in_grid = floor(sqrt(size(number_of_permutations,1))) * ceil(sqrt(size(number_of_permutations,1)));
for i=1:size(number_of_permutations,1)

    nexttile;
    scatter(peaks(number_of_permutations(i,1),:),peaks(number_of_permutations(i,2),:),1,[0.7 0.7 0.7],'filled');
    hold on;
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
if ismember("Z Score",bp_table_row.Properties.VariableNames)
    title_string = "Clustering Results for Channel Group "+string(strrep(bp_table_row{1,"Tetrode"},"t",""))+" (Channels "+strjoin(string(current_channels))+" Assembled due to physical promxity) with Threshold Multiplier k="+string(bp_table_row{1,"Z Score"});
elseif ismember("Multiplier",bp_table_row.Properties.VariableNames)
    title_string = "Clustering Results for Channel Group "+string(strrep(bp_table_row{1,"Tetrode"},"t",""))+" (Channels "+strjoin(string(current_channels))+" Assembled due to physical promxity) with Threshold Multiplier k="+string(bp_table_row{1,"Multiplier"});
end

sgtitle(title_string)
% close(f);
end