
unique_clusters = unique(tetrode_spike_clusters);

colors = distinguishable_colors(length(unique_clusters));


num_channels = size(the_aligned,1);

output_folder = '/Users/srijon/Downloads/ClusterWaveforms';

if ~exist(output_folder,'dir')
    mkdir(output_folder)
end

for c = 1:length(unique_clusters)

    current_cluster = unique_clusters(c);

    
    spike_indices = find(tetrode_spike_clusters == current_cluster);

    cluster_color = colors(c,:);

    for ch = 1:num_channels

        figure('Position',[100 100 800 500])

        
        waveforms = squeeze(the_aligned(ch, spike_indices, :));

        
        plot(waveforms','Color',cluster_color)

        xlabel('Time Samples')
        ylabel('Amplitude')

        title(['Cluster ',num2str(current_cluster), ...
              ' | Channel ',num2str(ch), ...
              ' | ',num2str(length(spike_indices)),' spikes'])

        % Save figure
        filename = sprintf('%s/Cluster_%d_Channel_%d.png', ...
                           output_folder, current_cluster, ch);

        saveas(gcf,filename)

        close

    end

end