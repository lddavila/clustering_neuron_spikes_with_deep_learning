%% Recording 6: expand an existing accuracy matrix to a lower cutoff
%
% By default this expands the old 15 percent matrix down to 5 percent. The
% accuracy-0 wrapper sets BASE_ACCURACY_CUTOFF to 0 and reuses the completed
% 5 percent matrix instead.

clearvars -except BASE_ACCURACY_CUTOFF
clc

total_tic = tic;

MINIMUM_SPIKES = 170;
if ~exist("BASE_ACCURACY_CUTOFF", "var")
    BASE_ACCURACY_CUTOFF = 5;
end

if BASE_ACCURACY_CUTOFF == 5
    OLD_ACCURACY_CUTOFF = 15;
elseif BASE_ACCURACY_CUTOFF == 0
    OLD_ACCURACY_CUTOFF = 5;
else
    error("This script currently supports a base cutoff of 5 or 0 percent.");
end

NUMBER_OF_WORKERS = 6;
CHECKPOINT_BATCH_SIZE = 50000;

TIMESTAMP_OVERLAP_CUTOFF = 5;
WAVEFORM_DISTANCE_CUTOFF = 220;
COUNCIL_PROBABILITY_CUTOFF = 0.95;


script_folder = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(script_folder)));

addpath(genpath(fullfile(repo_root, "clustering-master")));
addpath(genpath(fullfile(repo_root, "Utility_Functions")));
addpath(genpath(fullfile(repo_root, "Neural_Networks")));

cd(repo_root);

config = spikesort_config();

input_file = fullfile(repo_root, "Data", ...
    "6_600Neuron300SecondRecordingWithLevel6Noise", ...
    "blind_pass_table.mat");
result_folder = fullfile(repo_root, "Default_Results_Dir", ...
    "recording_6_accuracy_sweep");

if OLD_ACCURACY_CUTOFF == 15
    old_matrix_file = fullfile(repo_root, "Default_Results_Dir", ...
        "recording_6_new_pipeline", ...
        "recording_6_min170_accuracy15_merge_matrix.mat");
else
    old_matrix_file = fullfile(result_folder, ...
        "recording_6_min170_accuracy5_base_matrix.mat");
end

result_file = fullfile(result_folder, sprintf( ...
    "recording_6_min170_accuracy%d_base_matrix.mat", ...
    BASE_ACCURACY_CUTOFF));
checkpoint_file = fullfile(result_folder, sprintf( ...
    "recording_6_accuracy%d_matrix_checkpoint.mat", ...
    BASE_ACCURACY_CUTOFF));

if ~isfolder(result_folder)
    mkdir(result_folder);
end

if ~isfile(input_file)
    error("Recording 6 input file was not found:\n%s", input_file);
end

if ~isfile(old_matrix_file)
    error("The finished %d percent recording 6 matrix was not found.", ...
        OLD_ACCURACY_CUTOFF);
end

%% Load the recording and reproduce both filters

fprintf("\nRecording 6 accuracy sweep: matrix expansion\n");
fprintf("expanding the %d percent matrix down to %d percent\n", ...
    OLD_ACCURACY_CUTOFF, BASE_ACCURACY_CUTOFF);
fprintf("loading recording 6 and the existing matrix...\n");
load_tic = tic;

input_result = load(input_file, "data_to_save");
if ~isfield(input_result, "data_to_save") || ...
        ~istable(input_result.data_to_save)
    error("The recording file does not contain data_to_save.");
end

bp = input_result.data_to_save;
old_result = load(old_matrix_file);

if isfield(old_result, "kept_row_indices")
    old_row_indices = old_result.kept_row_indices(:);
    saved_old_accuracy_cutoff = old_result.MINIMUM_ACCURACY;
elseif isfield(old_result, "base_row_indices")
    old_row_indices = old_result.base_row_indices(:);
    saved_old_accuracy_cutoff = old_result.BASE_ACCURACY_CUTOFF;
else
    error("The old matrix does not contain its filtered row indices.");
end

if old_result.MINIMUM_SPIKES ~= MINIMUM_SPIKES || ...
        saved_old_accuracy_cutoff ~= OLD_ACCURACY_CUTOFF || ...
        old_result.TIMESTAMP_OVERLAP_CUTOFF ~= TIMESTAMP_OVERLAP_CUTOFF || ...
        old_result.WAVEFORM_DISTANCE_CUTOFF ~= WAVEFORM_DISTANCE_CUTOFF || ...
        old_result.COUNCIL_PROBABILITY_CUTOFF ~= COUNCIL_PROBABILITY_CUTOFF
    error("The existing higher-cutoff matrix used different settings.");
end

timestamp_column = bp{:, "timestamps"};
spike_count = zeros(height(bp), 1);

for cluster_id = 1:height(bp)
    timestamps = timestamp_column{cluster_id};
    if iscell(timestamps)
        timestamps = timestamps{1};
    end
    spike_count(cluster_id) = numel(timestamps);
end

cluster_accuracy = bp{:, "accuracy"};
base_row_indices = find(spike_count >= MINIMUM_SPIKES & ...
    cluster_accuracy >= BASE_ACCURACY_CUTOFF);

if any(~ismember(old_row_indices, base_row_indices))
    error("The higher-cutoff clusters are not a subset of the new filter.");
end

[~, old_positions] = ismember(old_row_indices, base_row_indices);
number_of_base_clusters = numel(base_row_indices);
number_of_old_clusters = numel(old_row_indices);
number_of_extra_clusters = number_of_base_clusters - number_of_old_clusters;

if ~isequal(size(old_result.merge_matrix), ...
        [number_of_old_clusters, number_of_old_clusters])
    error("The saved higher-cutoff matrix has the wrong size.");
end

fprintf("clusters at %d percent: %d\n", ...
    OLD_ACCURACY_CUTOFF, number_of_old_clusters);
fprintf("clusters at %d percent: %d\n", ...
    BASE_ACCURACY_CUTOFF, number_of_base_clusters);
fprintf("extra clusters:         %d\n", number_of_extra_clusters);
fprintf("loading took %.1f seconds\n", toc(load_tic));

%% List only the pairs that are missing from the old matrix

is_old_cluster = false(number_of_base_clusters, 1);
is_old_cluster(old_positions) = true;
is_extra_cluster = ~is_old_cluster;

number_of_all_pairs = number_of_base_clusters * ...
    (number_of_base_clusters - 1) / 2;
number_of_old_pairs = number_of_old_clusters * ...
    (number_of_old_clusters - 1) / 2;
number_of_new_pairs = number_of_all_pairs - number_of_old_pairs;

pair_row = zeros(number_of_new_pairs, 1, "uint32");
pair_column = zeros(number_of_new_pairs, 1, "uint32");
next_pair = 1;

for right_cluster = 2:number_of_base_clusters
    if is_extra_cluster(right_cluster)
        left_clusters = (1:right_cluster - 1).';
    else
        left_clusters = find(is_extra_cluster(1:right_cluster - 1));
    end

    if isempty(left_clusters)
        continue
    end

    rows_here = next_pair:(next_pair + numel(left_clusters) - 1);
    pair_row(rows_here) = uint32(left_clusters);
    pair_column(rows_here) = uint32(right_cluster);
    next_pair = rows_here(end) + 1;
end

if next_pair - 1 ~= number_of_new_pairs
    error("The missing-pair list has the wrong size.");
end

fprintf("old comparisons reused: %d\n", number_of_old_pairs);
fprintf("new comparisons needed: %d\n", number_of_new_pairs);

%% Load the same five networks

council_files = struct2table(dir( ...
    fullfile(config.DIR_TO_GROUP_OR_NOT_COUNCIL, "*.mat")));
council_files.folder = string(council_files.folder);
council_files.name = string(council_files.name);

split_names = split(erase(council_files.name, ".mat"), "_");
council_files.recording_number = str2double(split_names(:, end));
council_files = sortrows(council_files, "recording_number");

if height(council_files) ~= 5
    error("Expected five council networks, but found %d.", ...
        height(council_files));
end

council_nets = cell(5, 1);
fprintf("\nloading council networks...\n");
for net_id = 1:5
    council_nets{net_id} = importdata(fullfile( ...
        council_files.folder(net_id), council_files.name(net_id)));
    fprintf("  %s\n", council_files.name(net_id));
end

%% Prepare the lower-cutoff clusters for pair comparison

fprintf("\npreparing cluster information...\n");
setup_tic = tic;

bp_filtered = bp(base_row_indices, :);
requested_features = ["mean_waveform_rep_wire_1", "size", "rep_wire"];
assembled_features = assemble_data_for_neural_net( ...
    requested_features, bp_filtered, config);

all_waveforms = assembled_features{1};
all_rep_wires = assembled_features{3};
probe_locations = get_probe_xy();
all_wire_locations = probe_locations(all_rep_wires, :);

timestamp_column = bp_filtered{:, "timestamps"};
all_timestamps = cell(number_of_base_clusters, 1);
for cluster_id = 1:number_of_base_clusters
    timestamps = timestamp_column{cluster_id};
    if iscell(timestamps)
        timestamps = timestamps{1};
    end
    all_timestamps{cluster_id} = timestamps(:);
end

fprintf("cluster setup took %.1f seconds\n", toc(setup_tic));
clear bp bp_filtered assembled_features timestamp_column input_result

%% Resume the new comparisons if a matching checkpoint exists

merge_decision = false(number_of_new_pairs, 1);
last_pair_done = 0;

if isfile(checkpoint_file)
    checkpoint = load(checkpoint_file);
    checkpoint_matches = ...
        checkpoint.number_of_new_pairs == number_of_new_pairs && ...
        checkpoint.number_of_base_clusters == number_of_base_clusters && ...
        isequal(checkpoint.base_row_indices, base_row_indices) && ...
        checkpoint.TIMESTAMP_OVERLAP_CUTOFF == TIMESTAMP_OVERLAP_CUTOFF && ...
        checkpoint.WAVEFORM_DISTANCE_CUTOFF == WAVEFORM_DISTANCE_CUTOFF && ...
        checkpoint.COUNCIL_PROBABILITY_CUTOFF == COUNCIL_PROBABILITY_CUTOFF;

    if ~checkpoint_matches
        error("The existing accuracy-sweep checkpoint belongs to another run.");
    end

    merge_decision = checkpoint.merge_decision;
    last_pair_done = checkpoint.last_pair_done;
    fprintf("resuming after comparison %d / %d\n", ...
        last_pair_done, number_of_new_pairs);
end

%% Run only the missing comparisons

workers_for_parfor = 0;
if license("test", "Distrib_Computing_Toolbox")
    current_pool = gcp("nocreate");
    if isempty(current_pool)
        try
            current_pool = parpool("Processes", NUMBER_OF_WORKERS);
        catch pool_error
            fprintf("parallel pool failed: %s\n", pool_error.message);
        end
    end
    if ~isempty(current_pool)
        workers_for_parfor = min(NUMBER_OF_WORKERS, current_pool.NumWorkers);
    end
end

fprintf("\nchecking missing pairs with %d workers...\n", ...
    max(workers_for_parfor, 1));
compare_tic = tic;
first_pair_this_run = last_pair_done + 1;
time_delta = config.TIME_DELTA;

for batch_start = first_pair_this_run:CHECKPOINT_BATCH_SIZE:number_of_new_pairs
    batch_end = min(batch_start + CHECKPOINT_BATCH_SIZE - 1, ...
        number_of_new_pairs);
    batch_rows = double(pair_row(batch_start:batch_end));
    batch_columns = double(pair_column(batch_start:batch_end));
    batch_decisions = false(numel(batch_rows), 1);

    parfor (pair_in_batch = 1:numel(batch_rows), workers_for_parfor)
        left_cluster = batch_rows(pair_in_batch);
        right_cluster = batch_columns(pair_in_batch);
        merge_here = false;

        waveform_difference = all_waveforms(left_cluster, :) - ...
            all_waveforms(right_cluster, :);
        waveform_distance = sqrt(sum(waveform_difference .^ 2, "all"));

        if waveform_distance <= WAVEFORM_DISTANCE_CUTOFF
            timestamp_overlap = ...
                find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs( ...
                all_timestamps{left_cluster}, all_timestamps{right_cluster}, ...
                time_delta) * 100;

            if timestamp_overlap > TIMESTAMP_OVERLAP_CUTOFF
                wire_difference = all_wire_locations(left_cluster, :) - ...
                    all_wire_locations(right_cluster, :);
                wire_distance = sqrt(sum(wire_difference .^ 2, "all"));
                network_input = [timestamp_overlap, wire_distance, ...
                    waveform_distance];
                merge_here = true;

                for net_id = 1:5
                    scores = predict(council_nets{net_id}, network_input);
                    if scores(2) < COUNCIL_PROBABILITY_CUTOFF
                        merge_here = false;
                        break
                    end
                end
            end
        end

        batch_decisions(pair_in_batch) = merge_here;
    end

    merge_decision(batch_start:batch_end) = batch_decisions;
    last_pair_done = batch_end;

    save(checkpoint_file, "merge_decision", "last_pair_done", ...
        "number_of_new_pairs", "number_of_base_clusters", ...
        "base_row_indices", "TIMESTAMP_OVERLAP_CUTOFF", ...
        "WAVEFORM_DISTANCE_CUTOFF", "COUNCIL_PROBABILITY_CUTOFF", "-v7.3");

    completed_here = batch_end - first_pair_this_run + 1;
    elapsed = toc(compare_tic);
    pairs_per_second = completed_here / max(elapsed, eps);
    remaining_minutes = (number_of_new_pairs - batch_end) / ...
        max(pairs_per_second, eps) / 60;

    fprintf("checked %d / %d new pairs (%.1f%%) | links %d | " + ...
        "time %.1f min | remaining %.1f min\n", ...
        batch_end, number_of_new_pairs, ...
        100 * batch_end / number_of_new_pairs, ...
        sum(merge_decision(1:batch_end)), elapsed / 60, remaining_minutes);
end

%% Combine the old and new decisions into the exact lower-cutoff matrix

fprintf("\ncombining old and new matrix sections...\n");
merge_matrix = false(number_of_base_clusters, number_of_base_clusters);
merge_matrix(1:number_of_base_clusters + 1:end) = true;
merge_matrix(old_positions, old_positions) = logical(old_result.merge_matrix);

upper_positions = sub2ind(size(merge_matrix), double(pair_row), ...
    double(pair_column));
lower_positions = sub2ind(size(merge_matrix), double(pair_column), ...
    double(pair_row));
merge_matrix(upper_positions) = merge_decision;
merge_matrix(lower_positions) = merge_decision;

if ~isequal(merge_matrix(old_positions, old_positions), ...
        logical(old_result.merge_matrix))
    error("The reused higher-cutoff matrix changed unexpectedly.");
end

accepted_merge_links = nnz(triu(merge_matrix, 1));
council_network_names = council_files.name;
matrix_seconds = toc(compare_tic);
total_seconds = toc(total_tic);

save(result_file, "input_file", "base_row_indices", ...
    "old_row_indices", "old_positions", "merge_matrix", ...
    "accepted_merge_links", "council_network_names", ...
    "MINIMUM_SPIKES", "BASE_ACCURACY_CUTOFF", ...
    "TIMESTAMP_OVERLAP_CUTOFF", "WAVEFORM_DISTANCE_CUTOFF", ...
    "COUNCIL_PROBABILITY_CUTOFF", "number_of_old_pairs", ...
    "number_of_new_pairs", "matrix_seconds", "total_seconds", "-v7.3");

fprintf("%d percent base matrix: %d x %d\n", ...
    BASE_ACCURACY_CUTOFF, number_of_base_clusters, number_of_base_clusters);
fprintf("accepted merge links: %d\n", accepted_merge_links);
fprintf("saved base matrix to:\n%s\n", result_file);
fprintf("total script time: %.1f minutes\n", total_seconds / 60);
