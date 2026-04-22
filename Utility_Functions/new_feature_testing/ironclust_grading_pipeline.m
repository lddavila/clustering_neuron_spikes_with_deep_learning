current_script_file_path = mfilename('fullpath');
[current_file_path,~,~] = fileparts(current_script_file_path);
cd(current_file_path);
cd ../..
addpath(genpath(pwd));
config = spikesort_config;

%% Parameters
recording_num  = 1;
pre_samples    = 30;
post_samples   = 30;

tetrode        = build_artificial_tetrode;
n_tetrodes     = size(tetrode, 1);

%% ── Step 1 & 2: Load firings (convert .mda → .mat if needed) ────────────────
recording_name  = sprintf('%d_600Neuron300SecondRecordingWithLevel%dNoise', ...
                          recording_num, recording_num);
results_dir     = fullfile(config.base_file_path, 'Default_Results_Dir', recording_name);
firings_mat     = fullfile(results_dir, 'firings.mat');
firings_mda     = fullfile(config.base_file_path, 'Data', recording_name, 'firings.mda');
raw_data_dir    = fullfile(config.base_file_path, 'Data', recording_name, 'recordings_by_channel');

if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

if exist(firings_mat, 'file')
    fprintf('Loading existing firings.mat...\n');
    data    = load(firings_mat);
    firings = data.a;
else
    fprintf('Reading firings.mda...\n');
    firings = readmda(firings_mda);
    a       = firings;
    save(firings_mat, 'a');
    fprintf('Saved firings.mat to %s\n', firings_mat);
end

channels   = firings(1, :);
timestamps = firings(2, :);

% Load actual timestamps
ts_data           = load(fullfile(config.base_file_path, 'Data', recording_name, 'timestamps', 'timestamps.mat'));
ts_fn             = fieldnames(ts_data);
actual_timestamps = ts_data.(ts_fn{1});

%% ── Step 3: Cut spikes for all tetrodes ─────────────────────────────────────
fprintf('\n=== Step 3: Cutting spikes ===\n');
for tetrode_num = 1:n_tetrodes

    tetrode_out_dir = fullfile(results_dir, sprintf('t%d spikes', tetrode_num));
    spikes_file     = fullfile(tetrode_out_dir, 'spike_waveforms.mat');
    bp_file         = fullfile(tetrode_out_dir, 'bp_table.mat');

    if exist(spikes_file, 'file') && exist(bp_file, 'file')
        fprintf('Tetrode %d: spike_waveforms and bp_table already exist, skipping.\n', tetrode_num);
        continue;
    end

    unit_channels  = tetrode(tetrode_num, :);
    tetrode_spikes = ismember(channels, unit_channels);
    spike_idx      = find(tetrode_spikes);
    fprintf('Tetrode %d: found %d spikes\n', tetrode_num, numel(spike_idx));

    % Check all raw channel files exist before loading
    missing = false;
    for k = 1:4
        if ~exist(fullfile(raw_data_dir, sprintf('c%d.mat', unit_channels(k))), 'file')
            fprintf('Tetrode %d: missing raw data for channel %d, skipping.\n', tetrode_num, unit_channels(k));
            missing = true;
            break;
        end
    end
    if missing, continue; end

    % Load raw channel data
    raw = cell(1, 4);
    for k = 1:4
        ch     = unit_channels(k);
        d      = load(fullfile(raw_data_dir, sprintf('c%d.mat', ch)));
        fn     = fieldnames(d);
        raw{k} = double(d.(fn{1})(:)');
    end

    n_samples       = pre_samples + post_samples + 1;
    n_spikes        = numel(spike_idx);
    spike_waveforms = nan(4, n_spikes, n_samples);
    spike_info      = firings(:, spike_idx);

    for i = 1:n_spikes
        t  = timestamps(spike_idx(i));
        t0 = t - pre_samples;
        t1 = t + post_samples;
        for k = 1:4
            spike_waveforms(k, i, :) = raw{k}(t0:t1);
        end
    end

    % Create cluster indices
    unique_clusters = unique(spike_info(3, :));
    cluster_indices = cell(1, numel(unique_clusters));
    for c = 1:numel(unique_clusters)
        [~, cluster_indices{c}] = find(spike_info(3, :) == unique_clusters(c));
        cluster_indices{c}      = cluster_indices{c}(:);
    end

    % Filter out small clusters
    valid           = cellfun(@numel, cluster_indices) > 100;
    cluster_indices = cluster_indices(valid);
    unique_clusters = unique_clusters(valid);
    fprintf('Tetrode %d: %d clusters after filtering\n', tetrode_num, numel(unique_clusters));

    % Tvals
    number_of_std_above_means     = 20;
    mean_of_relevant_channels     = cellfun(@mean, raw)';
    std_dvns_of_relevant_channels = cellfun(@std,  raw)';
    tvals = mean_of_relevant_channels + (std_dvns_of_relevant_channels * number_of_std_above_means);

    % Build bp_table
    cluster_num_col = unique_clusters(:);
    tetrode_col     = repmat(tetrode_num, numel(unique_clusters), 1);
    timestamps_col  = arrayfun(@(c) actual_timestamps(spike_info(2, spike_info(3,:) == c)), ...
                               unique_clusters, 'UniformOutput', false);
    cluster_idx_col = cluster_indices(:);
    bp_table        = table(tetrode_col, cluster_num_col, timestamps_col.', cluster_idx_col, ...
        'VariableNames', {'Tetrode', 'Cluster', 'timestamps', 'cluster_idx'});

    if ~exist(tetrode_out_dir, 'dir'), mkdir(tetrode_out_dir); end
    save(spikes_file, 'spike_waveforms', 'spike_info', 'cluster_indices', ...
         'unique_clusters', 'unit_channels', 'tetrode_num', 'tvals');
    save(bp_file, 'bp_table');
    fprintf('Tetrode %d: saved spike_waveforms and bp_table\n', tetrode_num);
end

%% ── Steps 4 & 5: Interpolate and align all tetrodes ─────────────────────────
fprintf('\n=== Steps 4 & 5: Interpolating and aligning ===\n');
for tetrode_num = 1:n_tetrodes

    tetrode_out_dir = fullfile(results_dir, sprintf('t%d spikes', tetrode_num));
    aligned_file    = fullfile(tetrode_out_dir, sprintf('t%d_aligned.mat', tetrode_num));

    if ~exist(fullfile(tetrode_out_dir, 'spike_waveforms.mat'), 'file')
        fprintf('Tetrode %d: no spike_waveforms found, skipping.\n', tetrode_num);
        continue;
    end

    if exist(aligned_file, 'file')
        fprintf('Tetrode %d: aligned already exists, skipping.\n', tetrode_num);
        continue;
    end

    sw              = load(fullfile(tetrode_out_dir, 'spike_waveforms.mat'));
    spike_waveforms = sw.spike_waveforms;

    fprintf('Tetrode %d: interpolating...\n', tetrode_num);
    interpolated_spikes = interpolate_spikes(spike_waveforms, config);

    fprintf('Tetrode %d: aligning to peak...\n', tetrode_num);
    aligned = align_to_peak_ver_2(interpolated_spikes);
    save(aligned_file, 'aligned');
    fprintf('Tetrode %d: saved aligned\n', tetrode_num);
end

%% ── Load agreement scores ────────────────────────────────────────────────────
agreement_file = fullfile(config.base_file_path, 'Data', recording_name, 'agreement_scores.csv');
agreement_table = readtable(agreement_file, 'ReadRowNames', true);
% Extract numeric cluster IDs from sanitized column names (e.g. 'x_0', 'x_1')
agreement_cluster_ids = cellfun(@(x) str2double(regexp(x, '\d+', 'match', 'once')), agreement_table.Properties.VariableNames);
% Best accuracy per cluster = max over all ground truth rows * 100
agreement_matrix          = table2array(agreement_table);
best_accuracy_per_cluster = max(agreement_matrix, [], 1) * 100;  % 1 x n_clusters

%% ── Step 6: Grade all tetrodes ──────────────────────────────────────────────
fprintf('\n=== Step 6: Grading ===\n');
all_bp_rows = {};
startup
for tetrode_num = 1:n_tetrodes

    tetrode_out_dir = fullfile(results_dir, sprintf('t%d spikes', tetrode_num));
    aligned_file    = fullfile(tetrode_out_dir, sprintf('t%d_aligned.mat', tetrode_num));

    if ~exist(fullfile(tetrode_out_dir, 'spike_waveforms.mat'), 'file')
        fprintf('Tetrode %d: no spike_waveforms found, skipping.\n', tetrode_num);
        continue;
    end

    if exist(fullfile(tetrode_out_dir, sprintf('t%d_grades.mat', tetrode_num)), 'file')
        fprintf('Tetrode %d: grades already exist, skipping.\n', tetrode_num);
        continue;
    end

    sw  = load(fullfile(tetrode_out_dir, 'spike_waveforms.mat'));
    ld  = load(aligned_file);
    bpt = load(fullfile(tetrode_out_dir, 'bp_table.mat'));

    spike_info      = sw.spike_info;
    cluster_indices = sw.cluster_indices;
    unit_channels   = sw.unit_channels;
    tvals           = sw.tvals;
    aligned         = ld.aligned;

    fprintf('Tetrode %d: grading clusters...\n', tetrode_num);
    all_timestamps = spike_info(2, :);
    grades = compute_gradings_ver_4(aligned, all_timestamps, tvals', ...
        cluster_indices, config.spikesort, 0, unit_channels, ...
        config.TEMPLATE_CLUSTER_FP, config);
    grades_file = fullfile(tetrode_out_dir, sprintf('t%d_grades.mat', tetrode_num));
    save(grades_file, 'grades');
    fprintf('Tetrode %d: saved grades\n', tetrode_num);

    % Look up best accuracy for each cluster from agreement_scores
    sw_unique_clusters = sw.unique_clusters;
    accuracy_col = zeros(numel(sw_unique_clusters), 1);
    for c = 1:numel(sw_unique_clusters)
        col_match = find(agreement_cluster_ids == sw_unique_clusters(c), 1);
        if ~isempty(col_match)
            accuracy_col(c) = best_accuracy_per_cluster(col_match);
        else
            accuracy_col(c) = NaN;
        end
    end

    % Compute mean waveform per representative wire for each cluster
    n_clusters     = numel(cluster_indices);
    n_channels     = size(aligned, 1);
    mean_waveforms = cell(n_clusters, n_channels);
    all_peaks      = get_peaks(aligned, true);
    for c = 1:n_clusters
        cluster_filter = cluster_indices{c};
        spikes         = aligned(:, cluster_filter, :);
        peaks          = all_peaks(:, cluster_filter);
        for k = 1:n_channels
            [~, max_wire]          = max(peaks, [], 1);
            poss_wires             = unique(max_wire);
            n                      = histc(max_wire, poss_wires); %#ok<HISTC>
            [~, max_n]             = max(n);
            compare_wire           = poss_wires(max_n);
            peaks(compare_wire, :) = nan;
            mean_waveform          = mean(shiftdim(spikes(compare_wire, :, :), 1));
            mean_waveform          = mean_waveform - mean(mean_waveform);
            mean_waveforms{c, k}   = mean_waveform;
        end
    end

    % Add grades, accuracy, and mean waveforms to bp_table and collect
    bp_table_t          = bpt.bp_table;
    grades_col          = num2cell(grades, 2);
    bp_table_t.grades   = grades_col;
    bp_table_t.accuracy = accuracy_col;
    for k = 1:n_channels
        bp_table_t.(sprintf('mean_waveform_rep_wire_%d', k)) = mean_waveforms(:, k);
    end
    all_bp_rows{end+1} = bp_table_t;
end

%% Combine bp_tables from all tetrodes into one
bp_table_all = vertcat(all_bp_rows{:});
save(fullfile(results_dir, 'bp_table_all.mat'), 'bp_table_all');
fprintf('\nPipeline complete. Combined bp_table saved.\n');