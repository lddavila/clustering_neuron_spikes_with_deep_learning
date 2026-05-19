function [tetrode_spike_indices, tetrode_spike_template_ids] = ...
                get_spike_indices_per_tetrode(spike_templates, tetrode_template_ids)
%GET_SPIKE_INDICES_PER_TETRODE  Find spike indices and their template IDs
%   for every tetrode.
%
%   Inputs
%   ------
%   spike_templates      : [nSpikes x 1]  0-based Kilosort template IDs
%   tetrode_template_ids : {nTetrodes x 1} cell of 0-based cluster IDs
%
%   Outputs
%   -------
%   tetrode_spike_indices      : {nTetrodes x 1} 1-based indices into spike arrays
%   tetrode_spike_template_ids : {nTetrodes x 1} template ID for each spike on that tetrode

spike_templates = double(spike_templates(:));
num_tetrodes    = numel(tetrode_template_ids);

tetrode_spike_indices      = cell(num_tetrodes, 1);
tetrode_spike_template_ids = cell(num_tetrodes, 1);

for t = 1:num_tetrodes
    cluster_ids = double(tetrode_template_ids{t});

    if isempty(cluster_ids)
        tetrode_spike_indices{t}      = [];
        tetrode_spike_template_ids{t} = [];
        continue;
    end

    on_tetrode = ismember(spike_templates, cluster_ids);
    idx        = find(on_tetrode);

    tetrode_spike_indices{t}      = idx;
    tetrode_spike_template_ids{t} = spike_templates(idx);   % 0-based template ID per spike
end

total = sum(cellfun(@numel, tetrode_spike_indices));
active = sum(cellfun(@numel, tetrode_spike_indices) > 0);
fprintf('  Spikes assigned: %d across %d active tetrodes.\n', total, active);
end