function [cluster_templates,t,cluster_fc] = make_cluster_gmonopuls_templates(num_clusters,fs,waveform_ms)
%MAKE_CLUSTER_GMONOPULS_TEMPLATES Create one normalized gmonopuls template per cluster.

    num_samples = round(fs * waveform_ms / 1000);
    t = linspace(-waveform_ms/2, waveform_ms/2, num_samples) / 1000;

    cluster_templates = zeros(num_clusters,num_samples);
    cluster_fc = zeros(num_clusters,1);

    for cluster_idx = 1:num_clusters

        % Vary the center frequency to create shape differences
        fc = 700 + 1600 * rand();
        cluster_fc(cluster_idx) = fc;

        template = gmonopuls(t,fc);

        % Randomly allow polarity, or force negative-first
        [~,peak_idx] = max(abs(template));
        if template(peak_idx) > 0
            template = -template;
        end

        % Normalize absolute peak to 1
        template = template / max(abs(template));

        cluster_templates(cluster_idx,:) = template;
    end
end