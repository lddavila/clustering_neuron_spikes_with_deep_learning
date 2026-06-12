function [cluster_dim_templates,t,cluster_fc] = make_cluster_dim_gmonopuls_templates(num_clusters,total_dims)
%MAKE_CLUSTER_DIM_GMONOPULS_TEMPLATES
% Creates one template per cluster per dimension.
%
% Output:
%   cluster_dim_templates(cluster_idx,dim_idx,sample_idx)

num_samples = 60;
waveform_ms = 2.0;

t = linspace(-waveform_ms/2, waveform_ms/2, num_samples) * 1e-3; 
% t = linspace(-1, 1, num_samples);

cluster_dim_templates = zeros(num_clusters,total_dims,num_samples);
cluster_fc = zeros(num_clusters,1);

for cluster_idx = 1:num_clusters

    base_fc = 700 + 1600 * rand();
    cluster_fc(cluster_idx) = base_fc;

    for dim_idx = 1:total_dims

        fc = base_fc * (0.85 + 0.30 * rand());
        time_shift_sec = 0.00005 * randn(); % 0.05 ms jitter

        %template = gmonopuls(t - time_shift_sec,fc);
        template = gmonopuls(t,fc);

        [~,peak_idx] = max(abs(template));
        % if template(peak_idx) > 0
        %     template = -template;
        % end
        % disp(peak_idx);

        template = template / max(abs(template));

        cluster_dim_templates(cluster_idx,dim_idx,:) = template;
    end
end
end