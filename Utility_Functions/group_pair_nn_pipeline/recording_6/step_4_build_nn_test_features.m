%% Recording 6: build the complete nine-feature NN test dataset
%
% This script prepares every pair of remove_conflicts groups. It calculates
% the same nine inputs used to train the group-pair neural network and applies
% the normalization learned from the old training data.
%
% It does not run the neural network.

clearvars
clc

total_tic = tic;

NUMBER_OF_WORKERS = 6;
BATCH_SIZE = 100000;

script_folder = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(script_folder)));

addpath(genpath(fullfile(repo_root, "clustering-master")));
addpath(genpath(fullfile(repo_root, "Utility_Functions")));
addpath(genpath(fullfile(repo_root, "Neural_Networks")));
cd(repo_root);

result_folder = fullfile(repo_root, "Default_Results_Dir", ...
    "recording_6_new_pipeline");
group_file = fullfile(result_folder, ...
    "recording_6_min170_accuracy15_remove_conflicts.mat");
model_file = fullfile(repo_root, "Default_Results_Dir", ...
    "group_pair_nn_clear_experiment_result.mat");
dataset_file = fullfile(result_folder, ...
    "recording_6_complete_nn_test_features.mat");

if ~isfile(group_file)
    error("Run step_3_make_remove_conflicts_groups.m first.");
end

if ~isfile(model_file)
    error("The saved nine-feature neural-network experiment was not found.");
end

%% Load the groups, filtered table, and training normalization

fprintf("\nLoading recording 6 groups and the trained-model information...\n");
load_tic = tic;

group_result = load(group_file, "remove_conflicts_groups", ...
    "kept_row_indices", "input_file");
model_result = load(model_file, "feature_names", ...
    "final_feature_mean", "final_feature_std");
input_result = load(group_result.input_file, "data_to_save");

if ~isfield(input_result, "data_to_save") || ~istable(input_result.data_to_save)
    error("The original blind-pass table could not be loaded.");
end

starting_groups = group_result.remove_conflicts_groups;
kept_row_indices = group_result.kept_row_indices;
bp_filtered = input_result.data_to_save(kept_row_indices, :);
clear input_result

feature_names = string(model_result.feature_names(:));
feature_mean = model_result.final_feature_mean;
feature_std = model_result.final_feature_std;

expected_feature_names = [
    "small_timestamp_overlap"
    "large_timestamp_overlap"
    "matched_timestamps"
    "waveform_distance"
    "repwire_distance"
    "left_cluster_count"
    "right_cluster_count"
    "left_timestamp_count"
    "right_timestamp_count"
];

if ~isequal(feature_names, expected_feature_names)
    error("The saved neural network has a different feature order.");
end


number_of_clusters = height(bp_filtered);
number_of_groups = numel(starting_groups);
number_of_features = numel(feature_names);
number_of_pairs = number_of_groups * (number_of_groups - 1) / 2;

all_group_members = sort(vertcat(starting_groups{:}));
if ~isequal(all_group_members, (1:number_of_clusters).')
    error("The starting groups do not contain every filtered cluster exactly once.");
end

fprintf("filtered clusters:             %d\n", number_of_clusters);
fprintf("remove_conflicts groups:       %d\n", number_of_groups);
fprintf("complete group-pair dataset:   %d rows\n", number_of_pairs);
fprintf("features per row:              %d\n", number_of_features);
fprintf("loading took %.1f seconds\n", toc(load_tic));

%% Build one timestamp list, waveform, and location for each group

fprintf("\nPreparing group-level information...\n");
setup_tic = tic;

config = spikesort_config();
time_delta = config.TIME_DELTA;

timestamp_column = bp_filtered{:, "timestamps"};
cluster_timestamps = cell(number_of_clusters, 1);

for cluster_id = 1:number_of_clusters
    timestamps = timestamp_column{cluster_id};
    if iscell(timestamps)
        timestamps = timestamps{1};
    end
    cluster_timestamps{cluster_id} = timestamps(:);
end

group_timestamps = cell(number_of_groups, 1);
group_cluster_count = zeros(number_of_groups, 1);
group_timestamp_count = zeros(number_of_groups, 1);

for group_id = 1:number_of_groups
    members = starting_groups{group_id};
    timestamps = vertcat(cluster_timestamps{members});
    timestamps = unique(sort(timestamps));

    group_timestamps{group_id} = timestamps;
    group_cluster_count(group_id) = numel(members);
    group_timestamp_count(group_id) = numel(timestamps);

    if mod(group_id, 500) == 0 || group_id == number_of_groups
        fprintf("prepared %d / %d groups (%.1f%%), time %.1f sec\n", ...
            group_id, number_of_groups, 100 * group_id / number_of_groups, ...
            toc(setup_tic));
    end
end

all_waveforms = cell2mat(bp_filtered{:, "mean_waveform_rep_wire_1"});
group_waveforms = zeros(number_of_groups, size(all_waveforms, 2));

for group_id = 1:number_of_groups
    group_waveforms(group_id, :) = mean( ...
        all_waveforms(starting_groups{group_id}, :), 1);
end

probe_locations = get_probe_xy();
assembled_repwire = assemble_data_for_neural_net("rep_wire", bp_filtered, config);
cluster_repwire = assembled_repwire{1};
cluster_location = probe_locations(cluster_repwire, :);
group_location = zeros(number_of_groups, 2);

for group_id = 1:number_of_groups
    group_location(group_id, :) = mean( ...
        cluster_location(starting_groups{group_id}, :), 1);
end

fprintf("group setup took %.1f seconds\n", toc(setup_tic));

clear timestamp_column cluster_timestamps all_waveforms cluster_location
clear assembled_repwire bp_filtered model_result

%% Create or resume the on-disk dataset

source_group_file = group_file;
source_model_file = model_file;

if isfile(dataset_file)
    saved = load(dataset_file, "number_of_groups", "number_of_pairs", ...
        "number_of_features", "feature_names", "source_group_file", ...
        "source_model_file", "last_completed_pair", "dataset_complete");

    dataset_matches = ...
        saved.number_of_groups == number_of_groups && ...
        saved.number_of_pairs == number_of_pairs && ...
        saved.number_of_features == number_of_features && ...
        isequal(string(saved.feature_names(:)), feature_names) && ...
        string(saved.source_group_file) == string(source_group_file) && ...
        string(saved.source_model_file) == string(source_model_file);

    if ~dataset_matches
        error("The existing feature dataset belongs to a different experiment.");
    end

    if saved.dataset_complete
        fprintf("\nThe complete feature dataset already exists:\n%s\n", dataset_file);
        return
    end

    last_completed_pair = double(saved.last_completed_pair);
    fprintf("\nResuming after pair %d / %d\n", ...
        last_completed_pair, number_of_pairs);
else
    fprintf("\nCreating the on-disk feature dataset...\n");

    last_completed_pair = uint64(0);
    dataset_complete = false;

    save(dataset_file, "feature_names", "feature_mean", "feature_std", ...
        "number_of_groups", "number_of_pairs", "number_of_features", ...
        "group_cluster_count", "group_timestamp_count", ...
        "group_waveforms", "group_location", "source_group_file", ...
        "source_model_file", "last_completed_pair", "dataset_complete", ...
        "time_delta", "-v7.3");

    dataset = matfile(dataset_file, "Writable", true);

    % uint32 is enough for group IDs and uses half the space of doubles.
    group_a = zeros(number_of_pairs, 1, "uint32");
    group_b = zeros(number_of_pairs, 1, "uint32");
    next_row = 1;

    for right_group = 2:number_of_groups
        rows = next_row:(next_row + right_group - 2);
        group_a(rows) = uint32(1:right_group - 1);
        group_b(rows) = uint32(right_group);
        next_row = rows(end) + 1;
    end

    dataset.group_a = group_a;
    dataset.group_b = group_b;

    % Preallocate the two feature arrays directly inside the MAT file.
    dataset.raw_features(number_of_pairs, number_of_features) = single(0);
    dataset.normalized_features(number_of_pairs, number_of_features) = single(0);

    clear group_a group_b
end

dataset = matfile(dataset_file, "Writable", true);

%% Start parallel workers for the timestamp comparisons

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

%% Calculate and normalize all nine features

fprintf("\nBuilding the complete feature dataset...\n");
feature_tic = tic;
first_pair_this_run = double(last_completed_pair) + 1;
normalization_mean = single(feature_mean);
normalization_std = single(feature_std);

for batch_start = first_pair_this_run:BATCH_SIZE:number_of_pairs
    batch_end = min(batch_start + BATCH_SIZE - 1, number_of_pairs);
    batch_rows = batch_start:batch_end;

    left_group = double(dataset.group_a(batch_rows, 1));
    right_group = double(dataset.group_b(batch_rows, 1));
    rows_in_batch = numel(batch_rows);

    small_timestamp_overlap = zeros(rows_in_batch, 1);
    matched_timestamps = zeros(rows_in_batch, 1);

    parfor (pair_in_batch = 1:rows_in_batch, workers_for_parfor)
        left_id = left_group(pair_in_batch);
        right_id = right_group(pair_in_batch);

        [overlap, ~, matches] = ...
            find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs( ...
            group_timestamps{left_id}, group_timestamps{right_id}, time_delta);

        small_timestamp_overlap(pair_in_batch) = 100 * overlap;
        matched_timestamps(pair_in_batch) = matches;
    end

    larger_timestamp_count = max( ...
        group_timestamp_count(left_group), ...
        group_timestamp_count(right_group));
    large_timestamp_overlap = ...
        100 * matched_timestamps ./ larger_timestamp_count;

    waveform_difference = group_waveforms(left_group, :) - ...
        group_waveforms(right_group, :);
    waveform_distance = sqrt(sum(waveform_difference .^ 2, 2));

    location_difference = group_location(left_group, :) - ...
        group_location(right_group, :);
    repwire_distance = sqrt(sum(location_difference .^ 2, 2));

    raw_features = single([ ...
        small_timestamp_overlap, ...
        large_timestamp_overlap, ...
        matched_timestamps, ...
        waveform_distance, ...
        repwire_distance, ...
        group_cluster_count(left_group), ...
        group_cluster_count(right_group), ...
        group_timestamp_count(left_group), ...
        group_timestamp_count(right_group)]);

    normalized_features = ...
        (raw_features - normalization_mean) ./ normalization_std;

    dataset.raw_features(batch_rows, :) = raw_features;
    dataset.normalized_features(batch_rows, :) = normalized_features;
    dataset.last_completed_pair = uint64(batch_end);

    processed_this_run = batch_end - first_pair_this_run + 1;
    elapsed = toc(feature_tic);
    pairs_per_second = processed_this_run / max(elapsed, eps);
    seconds_remaining = ...
        (number_of_pairs - batch_end) / max(pairs_per_second, eps);

    fprintf("finished %d / %d pairs (%.1f%%) | time %.1f min | " + ...
        "estimated remaining %.1f min\n", ...
        batch_end, number_of_pairs, 100 * batch_end / number_of_pairs, ...
        elapsed / 60, seconds_remaining / 60);
end

dataset.dataset_complete = true;
dataset.total_seconds = toc(total_tic);

fprintf("\ncomplete normalized test dataset saved to:\n%s\n", dataset_file);
fprintf("dataset rows: %d\n", number_of_pairs);
fprintf("total script time: %.1f minutes\n", toc(total_tic) / 60);

%
