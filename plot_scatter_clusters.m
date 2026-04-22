a = importdata("tetrode1_spikes.mat");
colors = distinguishable_colors(length(a.cluster_indices));

pairs = nchoosek(1:4, 2);
figure;
t = tiledlayout(2, 3);

for p = 1:size(pairs, 1)
    ch1 = pairs(p, 1);
    ch2 = pairs(p, 2);
    nexttile; hold on;
    
    for i = 1:length(a.cluster_indices)
        x = min(squeeze(a.spike_waveforms(ch1, a.cluster_indices{i}, :)), [], 2);
        y = min(squeeze(a.spike_waveforms(ch2, a.cluster_indices{i}, :)), [], 2);
        scatter(x, y, 1, colors(i,:), 'filled', ...
            'DisplayName', sprintf('Cluster %d', a.unique_clusters(i)));
    end
    xlabel(sprintf("Ch %d",a.unit_channels(ch1)));
    ylabel(sprintf("Ch %d",a.unit_channels(ch2)));
    title(sprintf('Ch %d v Ch %d', a.unit_channels(ch1), a.unit_channels(ch2)));
    if p == 1
    legend('Location', 'best', 'FontSize', 6);
    legend show;
    end
end

timenow = datetime('now','InputFormat','yyyy-MM-dd HH:mm');
title(t,["Recording 1 Tetrode 1 Cluster Scatter Plots With IronClust Results",sprintf("Date Created: %s",timenow)]);
set(gcf,'Units','pixels','Position',[100 100 1600 900]);
drawnow;
saveas(gcf,'rrec1_tetrode1_IronClust_results.svg');