%edited by Luis David Davila and Alexander Friedman
function new_plot_waveforms(the_cf, the_raw_data)
    for c = 1:length(the_cf)
        cluster = the_cf{c};
        cluster_spikes = the_raw_data(:, cluster, :);
        other_spikes = the_raw_data(:, setdiff(1:size(the_raw_data, 2), cluster), :);
        minV = min(min(min(the_raw_data, [], 3), [], 2));
        maxV = max(max(max(the_raw_data, [], 3), [], 2));
        perm = randperm(size(other_spikes, 2));
        num_spikes = min(5000, size(other_spikes, 2));
        randindex = perm(1:num_spikes);
        for w = 1:size(the_raw_data, 1)
            figure
            hold on
            set(gca, 'ColorOrder', [0.8 0.8 0.8; 0.85 0.85 0.85; 0.9 0.9 0.9; 0.95 0.95 0.95])
            plot(squeeze(the_raw_data(w, randindex, :))')
            plot(shiftdim(cluster_spikes(w, :, :), 1)', 'k', 'LineWidth', 3)
            set(gca, 'XTick', [])
            xlim([1, size(the_raw_data, 3)]);
            ylim([minV, maxV])
            set(gca, 'XTick', [1, size(the_raw_data, 3)])
            set(gca, 'XTickLabel', {'0', '1'})
            xlabel('Time (ms)')
            ylabel('Voltage (\muV)')
            title(sprintf('Wire %d', w))
        end
    end
end