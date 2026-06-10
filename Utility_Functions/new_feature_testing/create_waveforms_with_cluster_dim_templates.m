function waveform_tensor = create_waveforms_with_cluster_dim_templates(X,spike_cluster_labels,cluster_dim_templates,noise_sigma)

    [num_spikes,num_dims] = size(X);
    [num_clusters,total_dims,num_samples] = size(cluster_dim_templates);

    if total_dims ~= num_dims
        error("Dimension mismatch: X has %i dims, templates have %i dims.", ...
            num_dims,total_dims);
    end

    waveform_tensor = zeros(num_spikes,num_samples,num_dims);

    for spike_idx = 1:num_spikes

        cluster_idx = spike_cluster_labels(spike_idx);

        for dim_idx = 1:num_dims

            if cluster_idx >= 1 && cluster_idx <= num_clusters
                template = squeeze(cluster_dim_templates(cluster_idx,dim_idx,:))';
            else
                template = squeeze(cluster_dim_templates(1,dim_idx,:))';
            end

            peak_mag = abs(X(spike_idx,dim_idx));

            waveform_tensor(spike_idx,:,dim_idx) = ...
                peak_mag * template + ...
                noise_sigma * randn(1,num_samples);
        end
    end
end