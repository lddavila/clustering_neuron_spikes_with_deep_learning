
a = importdata("tetrode1_spikes.mat");

acc_raw = readtable('agreement_scores.csv', 'ReadRowNames', true);
acc_matrix = acc_raw{:,:};
cluster_rows = a.unique_clusters + 1;
max_accuracy = max(acc_matrix(cluster_rows, :), [], 2) * 100;


bin_edges = 0:10:100;
n_bins = length(bin_edges) - 1;

pairs = nchoosek(1:4, 2);
timenow = datetime('now', 'InputFormat', 'yyyy-MM-dd HH:mm');

for b = 1:n_bins
    lo = bin_edges(b);
    hi = bin_edges(b + 1);

    if b == n_bins
        in_bin = find(max_accuracy >= lo & max_accuracy <= hi);
    else
        in_bin = find(max_accuracy >= lo & max_accuracy < hi);
    end

    if isempty(in_bin)
        continue;
    end

    colors = distinguishable_colors(length(in_bin));

    fig = figure;
    t = tiledlayout(2, 3);

    for p = 1:size(pairs, 1)
        ch1 = pairs(p, 1);
        ch2 = pairs(p, 2);
        nexttile; hold on;

        for idx = 1:length(in_bin)
            i = in_bin(idx);
            x = min(squeeze(a.spike_waveforms(ch1, a.cluster_indices{i}, :)), [], 2);
            y = min(squeeze(a.spike_waveforms(ch2, a.cluster_indices{i}, :)), [], 2);
            scatter(x, y, 1, colors(idx, :), 'filled', ...
                'DisplayName', sprintf('Cluster %d (%.1f%%)', a.unique_clusters(i), max_accuracy(i)));
        end

        xlabel(sprintf('Ch %d', a.unit_channels(ch1)));
        ylabel(sprintf('Ch %d', a.unit_channels(ch2)));
        title(sprintf('Ch %d v Ch %d', a.unit_channels(ch1), a.unit_channels(ch2)));

        if p == 1
            legend('Location', 'eastoutside', 'FontSize', 6);
            legend show;
        end
    end

    title(t, {sprintf('Recording 1 Tetrode 1 — Accuracy %d-%d%%', lo, hi), ...
              sprintf('Date Created: %s', timenow)});
    set(fig, 'Units', 'pixels', 'Position', [100 100 1600 900]);
    drawnow;
    saveas(fig, sprintf('rec1_tetrode1_IronClust_acc%02d_%02d.svg', lo, hi));
end