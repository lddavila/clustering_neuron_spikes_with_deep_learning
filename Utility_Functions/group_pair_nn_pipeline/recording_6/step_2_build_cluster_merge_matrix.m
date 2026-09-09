%% Recording 6: use the simple quality filter and build the merge matrix
%
% This script only does the first part of the new recording test:
%   1. load the new blind-pass table
%   2. load the rows kept by step_1_apply_quality_filter.m
%   3. compare every pair of remaining clusters with the five council nets
%   4. save the 0/1 merge matrix and a short evaluation summary
%
% It does not make groups yet. The remove_conflicts step will be separate so
% the matrix and these results can be checked first.

clearvars
clc

total_tic = tic;

%% Settings for this recording

NUMBER_OF_WORKERS = 6;
CHECKPOINT_BATCH_SIZE = 25000;

% These are the same pair-comparison cutoffs used in the original grouping
% function. Only the incompatible MUA step has been replaced.
TIMESTAMP_OVERLAP_CUTOFF = 5;
WAVEFORM_DISTANCE_CUTOFF = 220;
COUNCIL_PROBABILITY_CUTOFF = 0.95;

%% Find the repository and output folder

script_folder = fileparts(mfilename("fullpath"));
postprocessing_folder = fileparts(script_folder);
utility_folder = fileparts(postprocessing_folder);
repo_root = fileparts(utility_folder);
INPUT_FILE = fullfile(repo_root, "Data", ...
    "6_600Neuron300SecondRecordingWithLevel6Noise", ...
    "blind_pass_table.mat");

addpath(genpath(fullfile(repo_root, "clustering-master")));
addpath(genpath(fullfile(repo_root, "Utility_Functions")));
addpath(genpath(fullfile(repo_root, "Neural_Networks")));

% spikesort_config uses the current folder to find the repository.
cd(repo_root);
config = spikesort_config();

result_folder = fullfile(repo_root, "Default_Results_Dir", ...
    "recording_6_new_pipeline");
if ~isfolder(result_folder)
    mkdir(result_folder);
end

simple_filter_file = fullfile(result_folder, ...
    "recording_6_min170_accuracy15_filter.mat");
result_file = fullfile(result_folder, ...
    "recording_6_min170_accuracy15_merge_matrix.mat");
checkpoint_file = fullfile(result_folder, ...
    "recording_6_min170_accuracy15_matrix_checkpoint.mat");

if ~isfile(INPUT_FILE)
    error("The recording 6 blind-pass table was not found:\n%s", INPUT_FILE);
end

fprintf("\nRecording 6 filter and matrix test\n");
fprintf("input: %s\n", INPUT_FILE);
fprintf("results: %s\n\n", result_folder);

% Load the blind-pass table

fprintf("Loading the blind-pass table...\n");
load_tic = tic;

loaded_file = load(INPUT_FILE, "data_to_save");
if ~isfield(loaded_file, "data_to_save") || ~istable(loaded_file.data_to_save)
    error("The input MAT file does not contain the expected data_to_save table.");
end

bp = loaded_file.data_to_save;
clear loaded_file

raw_cluster_count = height(bp);
recording_name = string(bp{1, "recording_name"});
recording_name = recording_name(1);

has_answer_key = ismember("Max_Overlap_Unit", ...
    string(bp.Properties.VariableNames));

if has_answer_key
    raw_unit_for_cluster = bp{:, "Max_Overlap_Unit"};
    raw_units = unique(raw_unit_for_cluster);
    raw_unique_unit_count = numel(raw_units);
else
    raw_units = [];
    raw_unique_unit_count = NaN;
end

fprintf("recording: %s\n", recording_name);
fprintf("clusters before filtering: %d\n", raw_cluster_count);
if has_answer_key
    fprintf("unique units before filtering: %d\n", raw_unique_unit_count);
end
fprintf("loading took %.1f seconds\n", toc(load_tic));

%% Load the result of the simple quality filter

fprintf("\nLoading the simple quality filter result...\n");

if ~isfile(simple_filter_file)
    error("Run step_1_apply_quality_filter.m before building the matrix.");
end

simple_filter = load(simple_filter_file);
kept_row_indices = simple_filter.kept_row_indices;
removed_row_indices = simple_filter.removed_row_indices;

if any(kept_row_indices < 1) || any(kept_row_indices > raw_cluster_count) || ...
        numel(unique(kept_row_indices)) ~= numel(kept_row_indices)
    error("The saved filter row indices do not match this blind-pass table.");
end

keep_cluster = false(raw_cluster_count, 1);
keep_cluster(kept_row_indices) = true;
bp_filtered = bp(keep_cluster, :);

MINIMUM_SPIKES = simple_filter.MINIMUM_SPIKES;
MINIMUM_ACCURACY = simple_filter.MINIMUM_ACCURACY;
filter_seconds = simple_filter.filter_seconds;
filter_summary = simple_filter.filter_summary;

filtered_cluster_count = height(bp_filtered);
removed_cluster_count = numel(removed_row_indices);
cluster_retention_percent = 100 * filtered_cluster_count / raw_cluster_count;

if has_answer_key
    filtered_unit_for_cluster = bp_filtered{:, "Max_Overlap_Unit"};
    filtered_units = unique(filtered_unit_for_cluster);
    filtered_unique_unit_count = numel(filtered_units);
    units_removed_completely = setdiff(raw_units, filtered_units);
    removed_unit_count = numel(units_removed_completely);
    unit_retention_percent = 100 * filtered_unique_unit_count / raw_unique_unit_count;
else
    filtered_unit_for_cluster = [];
    filtered_units = [];
    filtered_unique_unit_count = NaN;
    units_removed_completely = [];
    removed_unit_count = NaN;
    unit_retention_percent = NaN;
end

fprintf("removed clusters: %d\n", removed_cluster_count);
fprintf("kept clusters: %d (%.1f%%)\n", ...
    filtered_cluster_count, cluster_retention_percent);
if has_answer_key
    fprintf("unique units after filtering: %d (%.1f%% retained)\n", ...
        filtered_unique_unit_count, unit_retention_percent);
    fprintf("units removed completely: %d\n", removed_unit_count);
end
fprintf("filtering took %.1f seconds\n", filter_seconds);

% The full input table is large. Only the filtered copy is needed in memory
% now, and the saved row indices can recreate it later.
clear bp simple_filter raw_unit_for_cluster

%% Load the five cluster-pair council networks

fprintf("\nLoading the cluster-pair council networks...\n");

council_files = struct2table(dir( ...
    fullfile(config.DIR_TO_GROUP_OR_NOT_COUNCIL, "*.mat")));
council_files.folder = string(council_files.folder);
council_files.name = string(council_files.name);

split_council_names = split(erase(council_files.name, ".mat"), "_");
council_files.recording_number = str2double(split_council_names(:, end));
council_files = sortrows(council_files, "recording_number");

if height(council_files) ~= 5
    error("Expected exactly five council networks, but found %d.", ...
        height(council_files));
end

council_nets = cell(5, 1);
for net_id = 1:5
    council_nets{net_id} = importdata(fullfile( ...
        council_files.folder(net_id), council_files.name(net_id)));
    fprintf("  %s\n", council_files.name(net_id));
end

%% Prepare the information needed for every cluster comparison

fprintf("\nPreparing cluster information...\n");
feature_tic = tic;

% These are the same three inputs prepared by the original grouping function.
requested_features = ["mean_waveform_rep_wire_1", "size", "rep_wire"];
assembled_features = assemble_data_for_neural_net( ...
    requested_features, bp_filtered, config);

all_waveforms = assembled_features{1};
all_rep_wires = assembled_features{3};

probe_locations = get_probe_xy();
all_wire_locations = probe_locations(all_rep_wires, :);

timestamp_column = bp_filtered{:, "timestamps"};
all_timestamps = cell(filtered_cluster_count, 1);

for cluster_id = 1:filtered_cluster_count
    timestamps = timestamp_column{cluster_id};
    if iscell(timestamps)
        timestamps = timestamps{1};
    end
    all_timestamps{cluster_id} = timestamps;
end

feature_seconds = toc(feature_tic);
fprintf("cluster information took %.1f seconds\n", feature_seconds);

%% List every unique cluster pair

[pair_row, pair_column] = find(triu(true(filtered_cluster_count), 1));
number_of_pairs = numel(pair_row);

fprintf("\nFiltered matrix size: %d x %d\n", ...
    filtered_cluster_count, filtered_cluster_count);
fprintf("unique cluster pairs to check: %d\n", number_of_pairs);

merge_decision = false(number_of_pairs, 1);
last_pair_done = 0;

%% Resume an unfinished matrix if a matching checkpoint exists

if isfile(checkpoint_file)
    checkpoint = load(checkpoint_file);

    checkpoint_matches = ...
        isfield(checkpoint, "number_of_filtered_clusters") && ...
        checkpoint.number_of_filtered_clusters == filtered_cluster_count && ...
        isfield(checkpoint, "number_of_pairs") && ...
        checkpoint.number_of_pairs == number_of_pairs && ...
        isfield(checkpoint, "checkpoint_input_file") && ...
        string(checkpoint.checkpoint_input_file) == INPUT_FILE && ...
        isfield(checkpoint, "merge_decision") && ...
        numel(checkpoint.merge_decision) == number_of_pairs && ...
        isfield(checkpoint, "last_pair_done") && ...
        isfield(checkpoint, "timestamp_overlap_cutoff") && ...
        checkpoint.timestamp_overlap_cutoff == TIMESTAMP_OVERLAP_CUTOFF && ...
        isfield(checkpoint, "waveform_distance_cutoff") && ...
        checkpoint.waveform_distance_cutoff == WAVEFORM_DISTANCE_CUTOFF && ...
        isfield(checkpoint, "council_probability_cutoff") && ...
        checkpoint.council_probability_cutoff == COUNCIL_PROBABILITY_CUTOFF;

    if ~checkpoint_matches
        error("The existing checkpoint does not match this run. " + ...
            "Move or delete it before restarting.");
    end

    merge_decision = checkpoint.merge_decision;
    last_pair_done = checkpoint.last_pair_done;
    fprintf("resuming after pair %d / %d\n", last_pair_done, number_of_pairs);
end

%% Start the parallel workers

workers_for_parfor = 0;

if license("test", "Distrib_Computing_Toolbox")
    current_pool = gcp("nocreate");

    if isempty(current_pool)
        try
            fprintf("\nStarting a pool with %d workers...\n", NUMBER_OF_WORKERS);
            current_pool = parpool("Processes", NUMBER_OF_WORKERS);
        catch pool_error
            fprintf("The parallel pool did not start. Using one process instead.\n");
            fprintf("MATLAB message: %s\n", pool_error.message);
        end
    end

    if ~isempty(current_pool)
        workers_for_parfor = min(NUMBER_OF_WORKERS, current_pool.NumWorkers);
        fprintf("using %d parallel workers\n", workers_for_parfor);
    end
end

if workers_for_parfor == 0
    fprintf("using a normal serial loop\n");
end

%% Build the 0/1 merge matrix

fprintf("\nBuilding the merge matrix...\n");
matrix_tic = tic;
first_pair_this_run = last_pair_done + 1;
time_delta = config.TIME_DELTA;

for batch_start = first_pair_this_run:CHECKPOINT_BATCH_SIZE:number_of_pairs
    batch_end = min(batch_start + CHECKPOINT_BATCH_SIZE - 1, number_of_pairs);
    batch_range = batch_start:batch_end;

    batch_rows = pair_row(batch_range);
    batch_columns = pair_column(batch_range);
    batch_decisions = false(numel(batch_range), 1);

    parfor (pair_in_batch = 1:numel(batch_range), workers_for_parfor)
        left_cluster = batch_rows(pair_in_batch);
        right_cluster = batch_columns(pair_in_batch);
        merge_this_pair = false;

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

                network_input = [timestamp_overlap, wire_distance, waveform_distance];
                merge_this_pair = true;

                for net_id = 1:5
                    network_scores = predict(council_nets{net_id}, network_input);
                    if network_scores(2) < COUNCIL_PROBABILITY_CUTOFF
                        merge_this_pair = false;
                        break
                    end
                end
            end
        end

        batch_decisions(pair_in_batch) = merge_this_pair;
    end

    merge_decision(batch_range) = batch_decisions;
    last_pair_done = batch_end;

    checkpoint_input_file = INPUT_FILE;
    number_of_filtered_clusters = filtered_cluster_count;
    timestamp_overlap_cutoff = TIMESTAMP_OVERLAP_CUTOFF;
    waveform_distance_cutoff = WAVEFORM_DISTANCE_CUTOFF;
    council_probability_cutoff = COUNCIL_PROBABILITY_CUTOFF;

    save(checkpoint_file, "merge_decision", "last_pair_done", ...
        "number_of_pairs", "number_of_filtered_clusters", ...
        "checkpoint_input_file", "timestamp_overlap_cutoff", ...
        "waveform_distance_cutoff", "council_probability_cutoff", "-v7.3");

    pairs_checked_this_run = last_pair_done - first_pair_this_run + 1;
    elapsed = toc(matrix_tic);
    pairs_per_second = pairs_checked_this_run / max(elapsed, eps);
    seconds_remaining = (number_of_pairs - last_pair_done) / ...
        max(pairs_per_second, eps);

    fprintf("checked %d / %d pairs (%.1f%%) | merge links %d | " + ...
        "time %.1f min | estimated remaining %.1f min\n", ...
        last_pair_done, number_of_pairs, ...
        100 * last_pair_done / number_of_pairs, ...
        sum(merge_decision(1:last_pair_done)), elapsed / 60, ...
        seconds_remaining / 60);
end

matrix_seconds = toc(matrix_tic);

merge_matrix = false(filtered_cluster_count, filtered_cluster_count);
merge_matrix(1:filtered_cluster_count + 1:end) = true;

upper_positions = sub2ind(size(merge_matrix), pair_row, pair_column);
lower_positions = sub2ind(size(merge_matrix), pair_column, pair_row);
merge_matrix(upper_positions) = merge_decision;
merge_matrix(lower_positions) = merge_decision;

accepted_merge_links = sum(merge_decision);

fprintf("\nMatrix finished.\n");
fprintf("accepted merge links: %d\n", accepted_merge_links);
fprintf("matrix comparison took %.1f minutes\n", matrix_seconds / 60);

%% Evaluate the matrix after all decisions are finished
%
% Max_Overlap_Unit is only an answer key here. Accuracy was used by the simple
% synthetic-data filter, but neither value is given to the council networks.

if has_answer_key
    same_unit_pair = filtered_unit_for_cluster(pair_row) == ...
        filtered_unit_for_cluster(pair_column);

    true_merge_links = sum(merge_decision & same_unit_pair);
    false_merge_links = sum(merge_decision & ~same_unit_pair);
    missed_same_unit_links = sum(~merge_decision & same_unit_pair);
    true_same_unit_pairs = sum(same_unit_pair);

    accepted_link_purity_percent = 100 * true_merge_links / ...
        max(accepted_merge_links, 1);
    same_unit_pair_recall_percent = 100 * true_merge_links / ...
        max(true_same_unit_pairs, 1);
else
    true_merge_links = NaN;
    false_merge_links = NaN;
    missed_same_unit_links = NaN;
    true_same_unit_pairs = NaN;
    accepted_link_purity_percent = NaN;
    same_unit_pair_recall_percent = NaN;
end

matrix_one_percent = 100 * accepted_merge_links / max(number_of_pairs, 1);

pair_summary = table(number_of_pairs, accepted_merge_links, ...
    true_same_unit_pairs, true_merge_links, false_merge_links, ...
    missed_same_unit_links, accepted_link_purity_percent, ...
    same_unit_pair_recall_percent, matrix_one_percent);

fprintf("\n--- Filter Summary ---\n");
disp(filter_summary);

fprintf("--- Matrix Pair Summary ---\n");
disp(pair_summary);

if has_answer_key
    fprintf("accepted-link purity: %.2f%%\n", accepted_link_purity_percent);
    fprintf("same-unit pair recall: %.2f%%\n", same_unit_pair_recall_percent);
end

fprintf("\nGroup purity and the groups/units ratio are not available yet. " + ...
    "Those require the remove_conflicts grouping step.\n");

%% Save the result needed for the next step

total_seconds = toc(total_tic);
input_file = INPUT_FILE;
filter_method = "at least 170 spikes and at least 15 percent accuracy";
council_network_names = council_files.name;

% The complete BP table is not duplicated here. kept_row_indices tells the
% next script exactly which rows to reload from the original input file.
save(result_file, "input_file", "recording_name", "kept_row_indices", ...
    "removed_row_indices", "merge_matrix", "filter_summary", ...
    "pair_summary", "units_removed_completely", "filter_method", ...
    "council_network_names", "MINIMUM_SPIKES", ...
    "MINIMUM_ACCURACY", ...
    "TIMESTAMP_OVERLAP_CUTOFF", ...
    "WAVEFORM_DISTANCE_CUTOFF", "COUNCIL_PROBABILITY_CUTOFF", ...
    "filter_seconds", "feature_seconds", "matrix_seconds", ...
    "total_seconds", "-v7.3");

fprintf("\nsaved result to:\n%s\n", result_file);
fprintf("total script time: %.1f minutes\n", total_seconds / 60);
