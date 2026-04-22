current_script_file_path = mfilename('fullpath');
[current_file_path,~,~] = fileparts(current_script_file_path);
cd(current_file_path);
cd ../..
addpath(genpath(pwd));
config = spikesort_config;

%% Parameters
recording_num = 1;
tetrode_num = 1;         
pre_samples = 30;        
post_samples = 30;        

%% Find channels for selected tetrode
tetrode = build_artificial_tetrode;
unit_channels = tetrode(tetrode_num, :); 

%% Load firings
data = load(fullfile(config.base_file_path,"Data",sprintf("%d_600Neuron300SecondRecordingWithLevel%dNoise",recording_num,recording_num),"firings.mat"));
firings = data.a;  

channels    = firings(1, :);
timestamps  = firings(2, :);
clusters    = firings(3, :);

%% Find spikes that belong to selected tetrode
tetrode_spikes = ismember(channels, unit_channels);
spike_idx  = find(tetrode_spikes);

fprintf('Found %d spikes on tetrode %d\n', numel(spike_idx), tetrode_num);

%% Load raw data for all 4 channels on the tetrode
raw = cell(1, 4);
for k = 1:4
    ch = unit_channels(k);
    d  = load(sprintf('c%d.mat', ch));
    fn = fieldnames(d);
    raw{k} = double(d.(fn{1})(:)');  
end

n_samples = pre_samples + post_samples + 1;
n_spikes  = numel(spike_idx);


spike_waveforms = nan(4, n_spikes, n_samples);
spike_info      = firings(:, spike_idx);


for i = 1:n_spikes
    t   = timestamps(spike_idx(i));
    t0  = t - pre_samples;
    t1  = t + post_samples;

 

    for k = 1:4
        spike_waveforms(k, i, :) = raw{k}(t0:t1);
    end
end

%% Group spike indices by cluster
unique_clusters = unique(spike_info(3, :));
cluster_indices = cell(1, numel(unique_clusters));
for c = 1:numel(unique_clusters)
    [~, cluster_indices{c}] = find(spike_info(3, :) == unique_clusters(c));
    cluster_indices{c} = cluster_indices{c}(:);  
end

% Get tvals
number_of_std_above_means = 20;
mean_of_relevant_channels = cellfun(@mean, raw)';  
std_dvns_of_relevant_channels = cellfun(@std, raw)';  
tvals = mean_of_relevant_channels + (std_dvns_of_relevant_channels * number_of_std_above_means);  

%% Build blind pass table
cluster_num_col   = unique_clusters(:);
tetrode_col       = repmat(tetrode_num, numel(unique_clusters), 1);
timestamps_col    = arrayfun(@(c) spike_info(2, spike_info(3,:) == c), unique_clusters, 'UniformOutput', false);
cluster_idx_col   = cluster_indices(:);

bp_table = table(cluster_num_col, tetrode_col, timestamps_col.', cluster_idx_col, ...
    'VariableNames', {'Cluster', 'Tetrode', 'Timestamps', 'ClusterIndices'});

%% Save spikes
output_file = sprintf('tetrode%d_spikes.mat', tetrode_num);
save(output_file, 'spike_waveforms', 'spike_info', 'cluster_indices','unique_clusters','unit_channels', 'tetrode_num','bp_table','tvals');
