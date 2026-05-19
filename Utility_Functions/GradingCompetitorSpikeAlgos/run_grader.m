%% ── 0. Configuration ────────────────────────────────────────────

clc; 

config_struct = spikesort_config();

current_dir = config_struct.base_file_path;

addpath(genpath(current_dir));

% Root data directory 
DATA_DIR   = fullfile(current_dir, 'Data');
assert(isfolder(DATA_DIR), ...
    'Data directory not found: %s', DATA_DIR);

SORTER_SUFFIX = "_resultskilosort4";

% Snippet size
WINDOW_SAMPLES = 30;

%% ── 1. Load tetrode array ────────────────────────────────────

art_tetr_array = config_struct.ART_TETR_ARRAY;

num_tetrodes = size(art_tetr_array, 1);
fprintf('Tetrode array loaded: %d tetrodes.\n', num_tetrodes);

%% ── 2. Get results folders ─────────────────────────────────

results_dirs = dir(fullfile(DATA_DIR, strcat('*', SORTER_SUFFIX)));
results_dirs = results_dirs([results_dirs.isdir]);
fprintf('Found %d recording pair(s).\n', numel(results_dirs));

%% ── 3. Loop over recording pairs ───────────────────────────────────
 
for rec_idx = 1:numel(results_dirs)

    results_name = results_dirs(rec_idx).name;
    rec_id = strrep(results_name, SORTER_SUFFIX, '');
    results_path = fullfile(DATA_DIR, results_name);

    aligned_dir = fullfile(results_path, 'aligned_data');
    if ~isfolder(aligned_dir)
        mkdir(aligned_dir);
    end

    cleaned_clusters_dir = fullfile(results_path, 'cleaned_clusters_data');
    reg_timestamps_dir = fullfile(results_path, 'reg_timestamps_data');

    if ~isfolder(cleaned_clusters_dir)
        mkdir(cleaned_clusters_dir);
    end

    if ~isfolder(reg_timestamps_dir)
        mkdir(reg_timestamps_dir);
    end

    raw_path = fullfile(DATA_DIR, rec_id);
    sorter_dir = fullfile(results_path, 'sorter_output');
    channel_dir = fullfile(raw_path, 'recordings_by_channel');
    timestamps_file = fullfile(raw_path, 'timestamps', 'timestamps.mat');
    
    checkpoint_file = fullfile(results_path, 'grading_checkpoint.mat');
    
    fprintf('\n[%d/%d] %s\n', rec_idx, numel(results_dirs), rec_id);


    % ── Load kilosort4 outputs ───────────────────────────────────────────────
    fprintf('  Loading kilosort4 outputs...\n');
    templates       = readNPY(fullfile(sorter_dir, 'templates.npy'));
    spike_templates = readNPY(fullfile(sorter_dir, 'spike_templates.npy'));
    spike_times_raw = readNPY(fullfile(sorter_dir, 'spike_times.npy'));
    fprintf('  templates: %s  |  spikes: %d\n', ...
            mat2str(size(templates)), numel(spike_templates));
 
    % ── Load timestamps ───────────────────────────────────────────────────
    fprintf('  Loading timestamps...\n');
    ts = load(timestamps_file);
    timestamps = double(ts.timestamps(:)');
 
    % ── Load channels ─────
    fprintf('  Loading channel traces...\n');
    needed_channels = unique(art_tetr_array(:));
    rec_data = struct();
    for c = 1:numel(needed_channels)
        ch_name = ['c' num2str(needed_channels(c))];
        ch = load(fullfile(channel_dir, [ch_name '.mat']));
        proper_ch_name = [ch_name(1), '_', ch_name(2:end)];
        rec_data.(ch_name) = double(ch.(proper_ch_name)(:));
    end
    fprintf('  Loaded %d channel(s).\n', numel(needed_channels));


    % ── Load agreement scores ─────────────────────────────────────────────
    fprintf('  Loading agreement scores...\n');
    agreement_file = fullfile(results_path, 'agreement_scores.csv');
    raw_csv        = readmatrix(agreement_file);   
    cluster_ids_csv    = raw_csv(:, 1);         
    agreement_matrix   = raw_csv(:, 2:end); % nClusters x nGroundTruthUnits
    accuracy_per_cluster_id = max(agreement_matrix, [], 2) * 100;  
    fprintf('  Agreement scores: %d clusters x %d ground truth units.\n', ...
            size(agreement_matrix, 1), size(agreement_matrix, 2));

 
    % ── Step 1: Representative channel per template ───────────────────────
    fprintf('  Step 1: rep channel...\n');
    rep_channel = get_representative_channel(templates);
 
    % ── Step 2: Assign templates to tetrodes ─────────────────────────────
    fprintf('  Step 2: template → tetrode assignment...\n');
    tetrode_template_ids = assign_templates_to_tetrodes(rep_channel, art_tetr_array);
 
    % ── Step 3: Spike indices per tetrode ────────────────────────────────
    fprintf('  Step 3: spike indices per tetrode...\n');
    [tetrode_spike_indices, tetrode_spike_template_ids] = ...
        get_spike_indices_per_tetrode(spike_templates, tetrode_template_ids);
 
    % ── Step 4: Spike times per tetrode ──────────────────────────────────
    fprintf('  Step 4: spike times per tetrode...\n');
    tetrode_spike_times = cell(num_tetrodes, 1);
    for t = 1:num_tetrodes
        idx_t = tetrode_spike_indices{t};
        if ~isempty(idx_t)
            tetrode_spike_times{t} = double(spike_times_raw(idx_t));
            tetrode_spike_times{t} = double(tetrode_spike_times{t})/30030.030030030026;
        end
    end
 
    % ── Step 5: Waveform snippets ─────────────────────────────────────────
    fprintf('  Step 5: waveform snippets...\n');
    tetrode_snippets = extract_waveform_snippets( ...
        tetrode_spike_times, timestamps, rec_data, art_tetr_array, WINDOW_SAMPLES);

    % ── Step 6: Interpolate spikes to 120 points ─────────────────────────
    fprintf('  Step 6: interpolating spikes...\n');
    tetrode_interp = cell(num_tetrodes, 1);
    for t = 1:num_tetrodes
        if isempty(tetrode_snippets{t})
            tetrode_interp{t} = [];
            continue;
        end
        spikes_permuted = permute(tetrode_snippets{t}, [2, 1, 3]);
        tetrode_interp{t}  = interpolate_spikes(spikes_permuted, config_struct);
        fprintf('    tetrode %d: %d spikes interpolated\n', t, size(tetrode_snippets{t}, 1));
    end
    fprintf('  Interpolation done.\n');


    % ── Step 7: Align spikes to peak ─────────────────────────────────────
    fprintf('  Step 7: aligning spikes to peak...\n');
    tetrode_aligned = cell(num_tetrodes, 1);
    for t = 1:num_tetrodes
        if isempty(tetrode_interp{t})
            tetrode_aligned{t} = [];
            continue;
        end
        tetrode_aligned{t} = align_to_peak_ver_2(tetrode_interp{t}, [], []);
        fprintf('    tetrode %d: aligned\n', t);
    end
    fprintf('  Alignment done.\n');

    % ── Save aligned data per tetrode ───────────────────────────────
    fprintf(' Saving aligned tetrode data...\n');

    for t = 1:num_tetrodes
    
        if isempty(tetrode_aligned{t})
            continue;
        end
    
        aligned = tetrode_aligned{t};
    
        aligned_fp = fullfile(aligned_dir, sprintf('t%d_aligned.mat', t));
    
        save(aligned_fp, 'aligned', '-v7.3');
    
    end
    
    fprintf(' Aligned data saved.\n');

    % ── Step 8: Grading setup ─────────────────────────────────────────────
    fprintf('  Step 8: setting up grading...\n');
    set(groot, 'defaultFigurePosition', [680 458 560 420]);
    set(groot, 'defaultFigureWindowStyle', 'normal');
    draw_elipse_templates(config_struct);
 
    % ── Step 9: Compute grades per tetrode ───────────────────────────────
    fprintf('  Step 9: computing grades...\n');

    % Load checkpoint if it exists
    if isfile(checkpoint_file)
        cp = load(checkpoint_file);
        tetrode_grades    = cp.tetrode_grades;
        tetrodes_done     = cp.tetrodes_done;
        fprintf('  Checkpoint found: %d / %d tetrodes already graded.\n', ...
                sum(tetrodes_done), num_tetrodes);
    else
        tetrode_grades = cell(num_tetrodes, 1);
        tetrodes_done  = false(num_tetrodes, 1);
    end


    % Loop through tetrodes

    for t = 1:num_tetrodes
 
        if tetrodes_done(t)
            fprintf('    tetrode %d: already done, skipping.\n', t);
            continue;
        end
 
        if isempty(tetrode_aligned{t})
            tetrode_grades{t} = [];
            tetrodes_done(t)  = true;
            continue;
        end
 
        channels_t = art_tetr_array(t, :);
 
        % tvals = mean + 20*std per channel
        ch_means = zeros(1, 4);
        ch_stds  = zeros(1, 4);
        for ch_pos = 1:4
            trace             = rec_data.(['c' num2str(channels_t(ch_pos))]);
            ch_means(ch_pos)  = mean(trace);
            ch_stds(ch_pos)   = std(trace);
        end
        tvals = ch_means + ch_stds * 20;
 
        % clusters cell array is spike indices per cluster within each tetrode
        spike_ids_t = tetrode_spike_template_ids{t};
        unique_ids  = unique(spike_ids_t);
        clusters    = cell(numel(unique_ids), 1);
        for k = 1:numel(unique_ids)
            clusters{k} = find(spike_ids_t == unique_ids(k));
        end
 
        fprintf('    tetrode %d: %d cluster(s), %d spike(s)...\n', ...
                t, numel(clusters), numel(spike_ids_t));

        % ── Regular timestamps per cluster ─────────────────────────────
        reg_timestamps_of_the_spikes = cell(numel(unique_ids), 1);
        
        for k = 1:numel(unique_ids)
    
            spike_idx_within_tetrode = clusters{k};
        
            reg_timestamps_of_the_spikes{k} = ...
                tetrode_spike_times{t}(spike_idx_within_tetrode);
        
        end
        
        % ── Save cleaned clusters ─────────────────────────────────────
        cleaned_clusters = clusters; %#ok<NASGU>
        
        cleaned_clusters_fp = fullfile( ...
            cleaned_clusters_dir, ...
            sprintf('t%d_cleaned_clusters.mat', t));
        
        save(cleaned_clusters_fp, 'cleaned_clusters', '-v7.3');
        
        % ── Save regular timestamps of spikes ─────────────────────────
        reg_timestamps_fp = fullfile( ...
            reg_timestamps_dir, ...
            sprintf('t%d_reg_timestamps.mat', t));
        
        save(reg_timestamps_fp, ...
            'reg_timestamps_of_the_spikes', ...
            '-v7.3');
 
        tetrode_grades{t} = compute_gradings_ver_4( ...
            tetrode_aligned{t}, ...
            tetrode_spike_times{t}, ...
            tvals, ...
            clusters, ...
            config_struct.spikesort, ...
            0, ...
            channels_t, ...
            config_struct.TEMPLATE_CLUSTER_FP, ...
            config_struct);
 
        tetrodes_done(t) = true;
 
        % Save checkpoint after every tetrode
        save(checkpoint_file, 'tetrode_grades', 'tetrodes_done', '-v7.3');
        fprintf('    tetrode %d: graded and checkpointed.\n', t);
    end
    fprintf('  Grading done. %d / %d tetrodes had spikes.\n', ...
            sum(~cellfun(@isempty, tetrode_grades)), num_tetrodes);



    % ── Step 10: Build blind pass table ──────────────────────────────────
    fprintf('  Step 10: building blind pass table...\n');
 
    % One row per cluster per tetrode
    row_tetrode  = [];
    row_cluster  = [];
    row_accuracy = [];
    row_grades   = []; 
    row_fp_to_aligned = {};
    row_fp_to_cleaned_clusters = {};
    row_fp_to_reg_timestamps_of_the_spikes = {};
 
    for t = 1:num_tetrodes
        if isempty(tetrode_grades{t})
            continue;
        end
 
        grades_t    = tetrode_grades{t};        
        spike_ids_t = tetrode_spike_template_ids{t};
        unique_ids  = unique(spike_ids_t); % 0-based Kilosort cluster IDs, one per row of grades_t
        nClusters_t = numel(unique_ids);
 
        for k = 1:nClusters_t
            cluster_id_0based = unique_ids(k);
 
            % Find accuracy from agreement_scores using cluster ID
            csv_row = find(cluster_ids_csv == cluster_id_0based, 1);
            if isempty(csv_row)
                acc = NaN;
            else
                acc = accuracy_per_cluster_id(csv_row);
            end

            aligned_fp = fullfile(aligned_dir, sprintf('t%d_aligned.mat', t));

            cleaned_clusters_fp = fullfile(cleaned_clusters_dir, sprintf('t%d_cleaned_clusters.mat', t));

            reg_timestamps_fp = fullfile(reg_timestamps_dir, sprintf('t%d_reg_timestamps.mat', t));
 
            row_tetrode  = [row_tetrode;  t];                  %#ok<AGROW>
            row_cluster  = [row_cluster;  cluster_id_0based];  %#ok<AGROW>
            row_accuracy = [row_accuracy; acc];                 %#ok<AGROW>
            row_grades   = [row_grades;   grades_t(k, :)];     %#ok<AGROW>
   
            row_fp_to_aligned{end+1,1} = aligned_fp; %#ok<AGROW>

            row_fp_to_cleaned_clusters{end+1,1} = cleaned_clusters_fp; %#ok<AGROW>

            row_fp_to_reg_timestamps_of_the_spikes{end+1,1} = reg_timestamps_fp; %#ok<AGROW>



        end
    end

    grades_cell = mat2cell(row_grades, ones(size(row_grades,1),1), size(row_grades,2));

    blind_pass_table = table( ...
    row_tetrode, ...
    row_cluster, ...
    row_accuracy, ...
    grades_cell, ...
    row_fp_to_aligned, ...
    row_fp_to_cleaned_clusters, ...
    row_fp_to_reg_timestamps_of_the_spikes, ...
    'VariableNames', ...
    {'Tetrode', 'Cluster', 'Accuracy', 'Grades', 'fp_to_aligned', 'fp_to_cleaned_clusters', 'fp_to_reg_timestamps_of_the_spikes'});
    
 
    % Save table as .csv and .mat
    table_csv = fullfile(results_path, 'blind_pass_table.csv');
    table_mat = fullfile(results_path, 'blind_pass_table.mat');
    writetable(blind_pass_table, table_csv);
    save(table_mat, 'blind_pass_table', '-v7.3');
    fprintf('  Blind pass table: %d rows saved.\n', height(blind_pass_table));
    fprintf('  CSV → %s\n', table_csv);

    % ── Step 11: Add waveforms ───────────────────
    fprintf(' Step 11: adding waveform metadata...\n');
    
    blind_pass_table = get_template_spike_idx_and_ts_for_clusters_kilosort4(blind_pass_table);
    
    % Re-save updated table
    writetable(blind_pass_table, table_csv);
    
    save(table_mat, 'blind_pass_table', '-v7.3');
    
    fprintf(' Waveform metadata added.\n');
 
    % ── Final save ────────────────────────────────────────────────────────
    save_path = fullfile(results_path, 'grading_results.mat');
    save(save_path, 'rec_id', 'rep_channel', 'tetrode_template_ids', ...
         'tetrode_spike_indices', 'tetrode_spike_times', 'tetrode_snippets', ...
         'tetrode_interp', 'tetrode_aligned', 'tetrode_grades', '-v7.3');
    fprintf('  Results saved → %s\n', save_path);
 
    % Remove checkpoint now that pipeline is complete
    if isfile(checkpoint_file)
        delete(checkpoint_file);
        fprintf('  Checkpoint cleared.\n');
    end


end
 
fprintf('\nDone. Processed %d recording(s).\n', numel(results_dirs));


