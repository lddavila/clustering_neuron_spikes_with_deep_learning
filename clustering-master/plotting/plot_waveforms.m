function plot_waveforms(cluster_filters, raw)
%PLOT_WAVEFORMS Plots the clusters individually in their raw waveform
%representations
    numdp = size(raw, 3);
    combined = reshape(permute(raw, [2 3 1]), [], numdp * 4);
    total_spikes = 1:size(combined, 1);
    
    for c = 1:length(cluster_filters)
%         colordef black
        figure
        set(gcf, 'Visible', 'off')
        hold on
        xlim([1 numdp*4])
        ymin = min(min(combined, [], 2));
        ymax = max(max(combined, [], 2));
        ylim([ymin ymax])
        cluster = cluster_filters{c};
        cluster_spikes = combined(cluster, :);
        other_spikes = combined(setdiff(total_spikes, cluster), :);
        
        other_length = size(other_spikes, 1);
        num_spikes = min(5000, other_length);
        perm = randperm(other_length);
        randindex = perm(1:num_spikes);
        set(gca, 'ColorOrder', [0.2 0.2 0.2; 0.4 0.4 0.4; 0.6 0.6 0.6; 0.75 0.75 0.75])
        plot(other_spikes(randindex, :)')
        
        plot(cluster_spikes', 'k')
        
        plot([numdp numdp], [ymin ymax], 'r')
        plot([numdp*2 numdp*2], [ymin ymax], 'r')
        plot([numdp*3 numdp*3], [ymin ymax], 'r')
        
        xlabel('Time (ms)');
        ylabel('Voltage (\muV)');
%         title(sprintf('Cluster %d', c));
        title('Nearly Synchronous Spikes Waveforms')
        set(gca, 'XTick', [1, numdp, numdp*2, numdp*3, numdp*4])
        set(gca, 'XTickLabel', {'0', '1 0', '1 0', '1 0', '1'})
        drawnow
        hold off
        set(gcf, 'Visible', 'on')
        set(gcf, 'InvertHardCopy', 'off')
    end
    colordef white
end