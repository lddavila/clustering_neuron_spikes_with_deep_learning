function new_plot_waveforms(cf, raw)
    for c = 1:length(cf)
        cluster = cf{c};
        cluster_spikes = raw(:, cluster, :);
        other_spikes = raw(:, setdiff(1:size(raw, 2), cluster), :);
        minV = min(min(min(raw, [], 3), [], 2));
        maxV = max(max(max(raw, [], 3), [], 2));
        perm = randperm(size(other_spikes, 2));
        num_spikes = min(5000, size(other_spikes, 2));
        randindex = perm(1:num_spikes);
        for w = 1:size(raw, 1)
            figure
            hold on
            set(gca, 'ColorOrder', [0.8 0.8 0.8; 0.85 0.85 0.85; 0.9 0.9 0.9; 0.95 0.95 0.95])
            plot(squeeze(raw(w, randindex, :))')
            plot(shiftdim(cluster_spikes(w, :, :), 1)', 'k', 'LineWidth', 3)
            set(gca, 'XTick', [])
            xlim([1, size(raw, 3)]);
            ylim([minV, maxV])
            set(gca, 'XTick', [1, size(raw, 3)])
            set(gca, 'XTickLabel', {'0', '1'})
            xlabel('Time (ms)')
            ylabel('Voltage (\muV)')
            title(sprintf('Wire %d', w))
        end
    end
end