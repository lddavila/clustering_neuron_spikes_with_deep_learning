pairs = [1 2; 1 3; 1 4; 2 3; 2 4; 3 4];

unique_clusters = unique(tetrode_spike_clusters);

colors = distinguishable_colors(size(unique_clusters, 1));

accuracy_bins = 0:10:100;
% 
% for b = 1:length(accuracy_bins)-1
% 
%     low = accuracy_bins(b);
%     high = accuracy_bins(b+1);
% 
%     % clusters that fall inside this accuracy range
%     cluster_mask = cluster_accuracy(unique_clusters+1) >= low & ...
%                    cluster_accuracy(unique_clusters+1) < high;
% 
%     clusters_in_bin = unique_clusters(cluster_mask);
% 
%     % skip empty ranges
%     if isempty(clusters_in_bin)
%         continue
%     end
% 
%     for i = 1:size(pairs,1)
% 
%         figure;
% 
%         ch1 = pairs(i,1);
%         ch2 = pairs(i,2);
% 
%         legend_str = repelem("", length(clusters_in_bin), 1);
% 
%         for j = 1:length(clusters_in_bin)
% 
%             current_cluster = clusters_in_bin(j);
% 
%             % get accuracy
%             acc = cluster_accuracy(current_cluster);
% 
%             legend_str(j) = "Cluster " + string(current_cluster) + ...
%                             " (" + num2str(acc,'%.1f') + "%)";
% 
%             scatter(peak_values(tetrode_spike_clusters==current_cluster,ch1), ...
%                     peak_values(tetrode_spike_clusters==current_cluster,ch2), ...
%                     2, colors(j,:), 'filled');
% 
%             hold on;
%         end
% 
%         ch1_label = ch1;
%         ch2_label = ch2;
% 
%         if ch1_label == 3
%             ch1_label = 97;
%         elseif ch1_label == 4
%             ch1_label = 98;
%         end
% 
%         if ch2_label == 3
%             ch2_label = 97;
%         elseif ch2_label == 4
%             ch2_label = 98;
%         end
% 
%         xlabel(['Channel ', num2str(ch1_label)]);
%         ylabel(['Channel ', num2str(ch2_label)]);
% 
%         title(['Clusters ', num2str(low), '-', num2str(high), ...
%                '% Accuracy | Channel ', num2str(ch1_label), ...
%                ' vs Channel ', num2str(ch2_label)]);
% 
%         legend(legend_str)
% 
%     end
% end



% pairs = [1 2; 1 3; 1 4; 2 3; 2 4; 3 4];
% accuracy_bins = 0:10:100;
% 
% unique_clusters = unique(tetrode_spike_clusters);
% 
% colors = distinguishable_colors(length(unique_clusters));
% 
% for i = 1:size(pairs,1)
% 
%     ch1 = pairs(i,1);
%     ch2 = pairs(i,2);
% 
% 
%     figure('Position',[100 100 1400 900])
%     tiledlayout(2,5,'TileSpacing','loose','Padding','loose')
% 
%     for b = 1:length(accuracy_bins)-1
% 
%         low = accuracy_bins(b);
%         high = accuracy_bins(b+1);
% 
%         nexttile
%         hold on
% 
%         legend_str = {};
%         plot_index = 0;
% 
%         for j = 1:length(unique_clusters)
% 
%             current_cluster = unique_clusters(j);
% 
%             acc = cluster_accuracy(current_cluster);
% 
%             if acc >= low && acc < high
% 
%                 spike_mask = tetrode_spike_clusters == current_cluster;
% 
%                 x = peak_values(spike_mask,ch1);
%                 y = peak_values(spike_mask,ch2);
% 
%                 plot_index = plot_index + 1;
% 
%                 scatter(x,y,2,colors(j,:),'filled')
% 
%                 legend_str{plot_index} = sprintf('C%d (%.1f%%)',current_cluster,acc);
% 
%             end
% 
%         end
% 
%         ch1_label = ch1;
%         ch2_label = ch2;
% 
%         if ch1_label == 3
%             ch1_label = 97;
%         elseif ch1_label == 4
%             ch1_label = 98;
%         end
% 
%         if ch2_label == 3
%             ch2_label = 97;
%         elseif ch2_label == 4
%             ch2_label = 98;
%         end
% 
%         xlabel(['Channel ',num2str(ch1_label)])
%         ylabel(['Channel ',num2str(ch2_label)])
% 
%         title(sprintf('%d-%d%% Accuracy',low,high))
% 
%         if ~isempty(legend_str)
%             legend(legend_str,'Location','bestoutside')
%         end
% 
%         hold off
% 
%     end
% 
%     sgtitle(['Channel ',num2str(ch1_label),' vs Channel ',num2str(ch2_label),' (Grouped by Accuracy)'])
% 
% end
% 



pairs = [1 2; 1 3; 1 4; 2 3; 2 4; 3 4];
accuracy_bins = 0:10:100;

unique_clusters = unique(tetrode_spike_clusters);

colors = distinguishable_colors(length(unique_clusters));

for b = 1:length(accuracy_bins)-1

    low = accuracy_bins(b);
    high = accuracy_bins(b+1);


    figure('Position',[100 100 1400 900])
    tiledlayout(2,5,'TileSpacing','loose','Padding','loose')

    for i = 1:size(pairs,1)

        ch1 = pairs(i,1);
        ch2 = pairs(i,2);

        nexttile
        hold on

        legend_str = {};
        plot_index = 0;

        for j = 1:length(unique_clusters)

            current_cluster = unique_clusters(j);

            acc = cluster_accuracy(current_cluster);

            if acc >= low && acc < high

                spike_mask = tetrode_spike_clusters == current_cluster;

                x = peak_values(spike_mask,ch1);
                y = peak_values(spike_mask,ch2);

                plot_index = plot_index + 1;

                scatter(x,y,2,colors(j,:),'filled')

                legend_str{plot_index} = sprintf('C%d (%.1f%%)',current_cluster,acc);

            end

        end

        ch1_label = ch1;
        ch2_label = ch2;

        if ch1_label == 3
            ch1_label = 97;
        elseif ch1_label == 4
            ch1_label = 98;
        end

        if ch2_label == 3
            ch2_label = 97;
        elseif ch2_label == 4
            ch2_label = 98;
        end

        xlabel(['Channel ',num2str(ch1_label)])
        ylabel(['Channel ',num2str(ch2_label)])

        title(sprintf('Ch %d vs Ch %d',ch1_label,ch2_label))

        if ~isempty(legend_str)
            legend(legend_str,'Location','bestoutside')
        end

        hold off

    end

    sgtitle(sprintf('Clusters with %d-%d%% Accuracy',low,high))

end


