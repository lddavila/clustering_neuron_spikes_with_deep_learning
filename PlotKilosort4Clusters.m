new_spike_times = double(spike_times.tolist());
new_spike_clusters = double(spike_clusters.tolist());

[u,~,ic] = unique(new_spike_clusters);
counts = accumarray(ic, 1);

figure;
bar(double(u), counts);
xlabel("cluster id");
ylabel("spike count");
title("Kilosort4: spikes per cluster");



sz = size(templates);
disp(sz);

unit = 1; 
W = squeeze(templates(unit,:,:)); 


ptp = max(W,[],1) - min(W,[],1);
[~,bestCh] = max(ptp);

figure;
plot(W(:,bestCh));
xlabel("samples");
ylabel("template amplitude (a.u.)");
title(sprintf("Kilosort4: template %d, best channel %d", unit, bestCh));
