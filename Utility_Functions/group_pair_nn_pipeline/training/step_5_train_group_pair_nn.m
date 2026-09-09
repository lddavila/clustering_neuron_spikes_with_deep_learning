%% Group-pair neural network experiment
% This script runs the complete experiment in one place:
%
%   1. load the prepared group-pair dataset
%   2. train the first network with 50/50 training rows
%   3. find difficult dont_merge examples from training units only
%   4. train a new network from scratch with those hard negatives
%   5. compare both networks on the same validation and test rows
%   6. choose the final grouping rule with validation units only
%   7. apply that locked rule once to the held-out test units
%
% Max_Overlap_Unit is used only to create supervised labels, keep units in
% separate train/validation/test splits, and evaluate the final groups. It is
% never included in the nine neural-network input features.

%

% fully_pure_group_percent =
% number of groups containing only one maxoverlap unit / total number of groups * 100
%
% mean_group_purity_percent =
% average of each group's purity * 100
% group purity = clusters from the most common unit / total clusters in the group
%
% clusters_in_pure_percent =
% clusters inside completely pure groups / total number of clusters * 100

clear
clc

total_tic = tic;
rng("default");

script_folder = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(script_folder)));
addpath(genpath(repo_root), "-begin");

%% Settings

TRAIN_DONT_MERGE_FRACTION = 0.50;
VALIDATION_DONT_MERGE_FRACTION = 0.60;

% The first network uses this result to find hard negatives.
HARD_NEGATIVE_PROBABILITY = 0.999;
HARD_NEGATIVE_SUPPORT = 1.00;

PROBABILITY_CUTOFFS = [0.95; 0.97; 0.99; 0.995; 0.999; 0.9995]; % merge probability
SUPPORT_CUTOFFS = [1.00; 0.90; 0.75];
PAIR_CHECK_CUTOFFS = [0.50; 0.70; 0.80; 0.90; 0.95; 0.97; 0.99; 0.995; 0.999; 0.9995];

MINI_BATCH_SIZE = 128;
MAX_EPOCHS = 50;
SCORING_BATCH_SIZE = 200000;

results_dir = fullfile(repo_root, "Default_Results_Dir");
dataset_file = fullfile(results_dir, "group_pair_nn_dataset.mat");
remove_conflicts_file = fullfile(results_dir, "remove_conflicts_only_result.mat");
timestamp_file = fullfile(results_dir, "simple_timestamp_reciprocal_grouping_result.mat");
waveform_file = fullfile(results_dir, "simple_euclidean_only_grouping_result.mat");
save_file = fullfile(results_dir, "group_pair_nn_clear_experiment_result.mat");

if ~isfile(dataset_file)
    error("The dataset is missing. Run step_4_build_nn_dataset.m first.");
end

if ~isfile(remove_conflicts_file) || ~isfile(timestamp_file) || ~isfile(waveform_file)
    error("The saved remove_conflicts, timestamp, or waveform data is missing.");
end

%% 1. Load the dataset and the saved all-pair measurements

fprintf("\n1. Loading the prepared data...\n");
load_tic = tic;

% The dataset supplies the unit split and the allowed feature names.
dataset = load(dataset_file, "feature_columns", "train_units", ...
    "validation_units", "test_units");

% These files supply information for all 5.3 million group pairs. The saved
% dataset tables contain sampled rows, so they are not enough by themselves
% for the final all-pair grouping stage.
start_data = load(remove_conflicts_file, ...
    "remove_conflicts_groups", "bp_filtered", "group_summary");
timestamp_data = load(timestamp_file, ...
    "smaller_overlap_percent", "reciprocal_overlap_percent", ...
    "matched_timestamps", "group_a", "group_b");
waveform_data = load(waveform_file, "waveform_distance", "group_a", "group_b");

if ~isequal(timestamp_data.group_a, waveform_data.group_a) || ...
        ~isequal(timestamp_data.group_b, waveform_data.group_b)
    error("Timestamp and waveform rows do not describe the same group pairs.");
end

starting_groups = start_data.remove_conflicts_groups;
bp_filtered = start_data.bp_filtered;
starting_group_summary = start_data.group_summary;
feature_names = string(dataset.feature_columns(:));

left_group = timestamp_data.group_a;
right_group = timestamp_data.group_b;

num_clusters = height(bp_filtered);
num_starting_groups = numel(starting_groups);
num_pairs = numel(left_group);

fprintf("clusters:               %d\n", num_clusters);
fprintf("remove_conflicts groups:%d\n", num_starting_groups);
fprintf("saved group pairs:      %d\n", num_pairs);
fprintf("train units:            %d\n", numel(dataset.train_units));
fprintf("validation units:       %d\n", numel(dataset.validation_units));
fprintf("test units:             %d\n", numel(dataset.test_units));
fprintf("loading took %.1f seconds\n", toc(load_tic));

%% 2. Prepare the group information used by the nine features

fprintf("\n2. Preparing group information...\n");
setup_tic = tic;

group_is_pure = starting_group_summary.is_pure;
group_unit = starting_group_summary.dominant_unit;
group_cluster_count = starting_group_summary.group_size;
max_overlap_unit = bp_filtered{:, "Max_Overlap_Unit"};

group_timestamp_count = count_group_timestamps(starting_groups, bp_filtered);
repwire_distance = calculate_repwire_distance(starting_groups, bp_filtered, ...
    left_group, right_group);

cluster_to_starting_group = zeros(num_clusters, 1);
for group_id = 1:num_starting_groups
    cluster_to_starting_group(starting_groups{group_id}) = group_id;
end

% These subsets contain only pure starting groups assigned to one split.
% Max_Overlap_Unit is used here to define the experimental split, not as a
% neural-network input.
training_grouping_data = make_grouping_subset(dataset.train_units, ...
    starting_groups, group_is_pure, group_unit, left_group, right_group, ...
    max_overlap_unit);
validation_grouping_data = make_grouping_subset(dataset.validation_units, ...
    starting_groups, group_is_pure, group_unit, left_group, right_group, ...
    max_overlap_unit);
test_grouping_data = make_grouping_subset(dataset.test_units, ...
    starting_groups, group_is_pure, group_unit, left_group, right_group, ...
    max_overlap_unit);

print_grouping_subset("training", training_grouping_data);
print_grouping_subset("validation", validation_grouping_data);
print_grouping_subset("test", test_grouping_data);

fprintf("group setup took %.1f seconds\n", toc(setup_tic));

%% 3. Make one fixed set of train, validation, and test rows

fprintf("\n3. Making the train, validation, and test rows...\n");
row_tic = tic;

% Both groups in a supervised row must be pure and must belong to units from
% the same split. This prevents one biological unit from crossing splits.
all_train_rows = rows_for_units(dataset.train_units, group_is_pure, ...
    group_unit, left_group, right_group);
all_validation_rows = rows_for_units(dataset.validation_units, group_is_pure, ...
    group_unit, left_group, right_group);
all_test_rows = rows_for_units(dataset.test_units, group_is_pure, ...
    group_unit, left_group, right_group);

train_is_merge = pair_labels(all_train_rows, group_unit, left_group, right_group);
validation_is_merge = pair_labels(all_validation_rows, group_unit, left_group, right_group);
test_is_merge = pair_labels(all_test_rows, group_unit, left_group, right_group);

% The same sampled rows are reused for both networks. That makes the baseline
% and hard-negative comparison easier to interpret.
base_train_rows = sample_rows(all_train_rows, train_is_merge, ...
    TRAIN_DONT_MERGE_FRACTION);
validation_rows = sample_rows(all_validation_rows, validation_is_merge, ...
    VALIDATION_DONT_MERGE_FRACTION);
balanced_test_rows = sample_rows(all_test_rows, test_is_merge, 0.50);

print_row_counts("base training", base_train_rows, group_unit, left_group, right_group);
print_row_counts("validation", validation_rows, group_unit, left_group, right_group);
print_row_counts("balanced test", balanced_test_rows, group_unit, left_group, right_group);
print_row_counts("natural test", all_test_rows, group_unit, left_group, right_group);
fprintf("row setup took %.1f seconds\n", toc(row_tic));

%% 4. Build and normalize the baseline inputs

fprintf("\n4. Building the baseline inputs...\n");
input_tic = tic;

X_train_raw = feature_matrix(base_train_rows, timestamp_data, waveform_data, ...
    repwire_distance, group_cluster_count, group_timestamp_count, ...
    left_group, right_group, feature_names);
Y_train = categorical(pair_labels(base_train_rows, group_unit, left_group, right_group), ...
    [false true], {'dont_merge', 'merge'});

X_validation_raw = feature_matrix(validation_rows, timestamp_data, waveform_data, ...
    repwire_distance, group_cluster_count, group_timestamp_count, ...
    left_group, right_group, feature_names);
Y_validation = categorical(pair_labels(validation_rows, group_unit, left_group, right_group), ...
    [false true], {'dont_merge', 'merge'});

X_test_balanced_raw = feature_matrix(balanced_test_rows, timestamp_data, waveform_data, ...
    repwire_distance, group_cluster_count, group_timestamp_count, ...
    left_group, right_group, feature_names);
Y_test_balanced = categorical(pair_labels(balanced_test_rows, group_unit, left_group, right_group), ...
    [false true], {'dont_merge', 'merge'});

X_test_natural_raw = feature_matrix(all_test_rows, timestamp_data, waveform_data, ...
    repwire_distance, group_cluster_count, group_timestamp_count, ...
    left_group, right_group, feature_names);
Y_test_natural = categorical(test_is_merge, [false true], {'dont_merge', 'merge'});

[X_train, baseline_feature_mean, baseline_feature_std] = normalize_training_data(X_train_raw);
X_validation_baseline = apply_normalization(X_validation_raw, ...
    baseline_feature_mean, baseline_feature_std);
X_test_balanced_baseline = apply_normalization(X_test_balanced_raw, ...
    baseline_feature_mean, baseline_feature_std);
X_test_natural_baseline = apply_normalization(X_test_natural_raw, ...
    baseline_feature_mean, baseline_feature_std);

fprintf("input setup took %.1f seconds\n", toc(input_tic));

%% 5. Train the baseline network

fprintf("\n5. Training the baseline network...\n");
baseline_train_tic = tic;

baseline_layers = group_pair_layers(numel(feature_names));
baseline_options = group_pair_training_options(X_validation_baseline, Y_validation, ...
    MINI_BATCH_SIZE, MAX_EPOCHS);

baseline_net = trainnet(X_train, Y_train, baseline_layers, ...
    "crossentropy", baseline_options);

fprintf("baseline training took %.1f seconds\n", toc(baseline_train_tic));

baseline_pair_summary = evaluate_model(baseline_net, ...
    X_train, Y_train, X_validation_baseline, Y_validation, ...
    X_test_balanced_baseline, Y_test_balanced, ...
    X_test_natural_baseline, Y_test_natural, "baseline");

fprintf("\nBaseline pair-level results at probability 0.50\n");
disp(baseline_pair_summary);

baseline_validation_cutoffs = evaluate_cutoffs(baseline_net, ...
    X_validation_baseline, Y_validation, PAIR_CHECK_CUTOFFS, "baseline_validation");

fprintf("\nBaseline validation cutoff results\n");
disp(baseline_validation_cutoffs);

%% 6. Score all pairs and make the training-only hard-negative groups

fprintf("\n6. Scoring every pair with the baseline network...\n");
baseline_probability = score_all_pairs(baseline_net, timestamp_data, waveform_data, ...
    repwire_distance, group_cluster_count, group_timestamp_count, ...
    left_group, right_group, feature_names, baseline_feature_mean, ...
    baseline_feature_std, SCORING_BATCH_SIZE);

% Hard negatives must be discovered without using validation or test units.
fprintf("\nTesting the fixed hard-negative rule on training units only...\n");
[baseline_training_grouping_summary, baseline_training_groups, ...
    baseline_training_group_summaries] = test_grouping_rules( ...
    "baseline_training_only", training_grouping_data.groups, ...
    training_grouping_data.left_group, training_grouping_data.right_group, ...
    baseline_probability(training_grouping_data.pair_rows), ...
    HARD_NEGATIVE_PROBABILITY, HARD_NEGATIVE_SUPPORT, ...
    max_overlap_unit, training_grouping_data.num_clusters);

disp(baseline_training_grouping_summary);

%% 7. Find hard negatives from training units only

fprintf("\n7. Finding training-only hard negatives...\n");
hard_negative_tic = tic;

hard_negative_rows = harvest_hard_negatives( ...
    baseline_training_groups{1}, baseline_training_group_summaries{1}, ...
    cluster_to_starting_group, group_is_pure, group_unit, dataset.train_units, ...
    left_group, right_group, num_starting_groups);

new_hard_negative_rows = setdiff(hard_negative_rows, base_train_rows);
hard_negative_train_rows = unique([base_train_rows; hard_negative_rows]);

fprintf("hard negatives found:          %d\n", numel(hard_negative_rows));
fprintf("new rows added to training:    %d\n", numel(new_hard_negative_rows));
print_row_counts("hard-negative training", hard_negative_train_rows, ...
    group_unit, left_group, right_group);
fprintf("hard-negative setup took %.1f seconds\n", toc(hard_negative_tic));

%% 8. Train a new network from scratch with the hard negatives

fprintf("\n8. Training a new network from scratch with hard negatives...\n");
hard_train_tic = tic;

X_hard_train_raw = feature_matrix(hard_negative_train_rows, timestamp_data, ...
    waveform_data, repwire_distance, group_cluster_count, group_timestamp_count, ...
    left_group, right_group, feature_names);
Y_hard_train = categorical(pair_labels(hard_negative_train_rows, group_unit, ...
    left_group, right_group), [false true], {'dont_merge', 'merge'});

% Normalization is recalculated from the revised training data only.
[X_hard_train, hard_feature_mean, hard_feature_std] = ...
    normalize_training_data(X_hard_train_raw);
X_validation_hard = apply_normalization(X_validation_raw, ...
    hard_feature_mean, hard_feature_std);
X_test_balanced_hard = apply_normalization(X_test_balanced_raw, ...
    hard_feature_mean, hard_feature_std);
X_test_natural_hard = apply_normalization(X_test_natural_raw, ...
    hard_feature_mean, hard_feature_std);

hard_negative_layers = group_pair_layers(numel(feature_names));
hard_negative_options = group_pair_training_options(X_validation_hard, Y_validation, ...
    MINI_BATCH_SIZE, MAX_EPOCHS);

% This creates new weights. It does not continue training baseline_net.
hard_negative_net = trainnet(X_hard_train, Y_hard_train, ...
    hard_negative_layers, "crossentropy", hard_negative_options);

fprintf("hard-negative training took %.1f seconds\n", toc(hard_train_tic));

hard_negative_pair_summary = evaluate_model(hard_negative_net, ...
    X_hard_train, Y_hard_train, X_validation_hard, Y_validation, ...
    X_test_balanced_hard, Y_test_balanced, ...
    X_test_natural_hard, Y_test_natural, "hard_negative");

fprintf("\nHard-negative pair-level results at probability 0.50\n");
disp(hard_negative_pair_summary);

hard_negative_validation_cutoffs = evaluate_cutoffs(hard_negative_net, ...
    X_validation_hard, Y_validation, PAIR_CHECK_CUTOFFS, ...
    "hard_negative_validation");

fprintf("\nHard-negative validation cutoff results\n");
disp(hard_negative_validation_cutoffs);

%% 9. Score all pairs with the hard-negative network

fprintf("\n9. Scoring every pair with the hard-negative network...\n");
hard_negative_probability = score_all_pairs(hard_negative_net, timestamp_data, ...
    waveform_data, repwire_distance, group_cluster_count, group_timestamp_count, ...
    left_group, right_group, feature_names, hard_feature_mean, ...
    hard_feature_std, SCORING_BATCH_SIZE);

%% 10. Choose the policy with validation units, then test it once

fprintf("\n10. Selecting the grouping rule with validation units only...\n");

[baseline_validation_grouping_summary, ~, ~] = test_grouping_rules( ...
    "baseline_validation_only", validation_grouping_data.groups, ...
    validation_grouping_data.left_group, validation_grouping_data.right_group, ...
    baseline_probability(validation_grouping_data.pair_rows), ...
    PROBABILITY_CUTOFFS, SUPPORT_CUTOFFS, max_overlap_unit, ...
    validation_grouping_data.num_clusters);

[hard_validation_grouping_summary, ~, ~] = test_grouping_rules( ...
    "hard_negative_validation_only", validation_grouping_data.groups, ...
    validation_grouping_data.left_group, validation_grouping_data.right_group, ...
    hard_negative_probability(validation_grouping_data.pair_rows), ...
    PROBABILITY_CUTOFFS, SUPPORT_CUTOFFS, max_overlap_unit, ...
    validation_grouping_data.num_clusters);

selected_validation_row = choose_validation_policy(hard_validation_grouping_summary);
selected_probability_cutoff = selected_validation_row.probability_cutoff;
selected_support_cutoff = selected_validation_row.support_cutoff;

fprintf("\nSelected from validation: probability %.4f, support %.2f\n", ...
    selected_probability_cutoff, selected_support_cutoff);
disp(selected_validation_row);

fprintf("\nApplying the locked validation policy to the 69 test units once...\n");
[final_test_grouping_summary, final_test_groups, final_test_group_summaries] = ...
    test_grouping_rules("hard_negative_test_only", test_grouping_data.groups, ...
    test_grouping_data.left_group, test_grouping_data.right_group, ...
    hard_negative_probability(test_grouping_data.pair_rows), ...
    selected_probability_cutoff, selected_support_cutoff, ...
    max_overlap_unit, test_grouping_data.num_clusters);

fprintf("\nFINAL HELD-OUT TEST GROUPING RESULT\n");
fprintf("expected units / ideal groups: %d\n", test_grouping_data.num_units);
disp(final_test_grouping_summary);

%% 11. Compare the full-data exploratory results

fprintf("\n11. Full-data comparison (exploratory, not the held-out test result)\n");

[baseline_grouping_summary, baseline_groups, baseline_group_summaries] = ...
    test_grouping_rules("baseline_full_data", starting_groups, left_group, ...
    right_group, baseline_probability, PROBABILITY_CUTOFFS, SUPPORT_CUTOFFS, ...
    max_overlap_unit, num_clusters);

[hard_negative_grouping_summary, hard_negative_groups, ...
    hard_negative_group_summaries] = test_grouping_rules( ...
    "hard_negative_full_data", starting_groups, left_group, right_group, ...
    hard_negative_probability, PROBABILITY_CUTOFFS, SUPPORT_CUTOFFS, ...
    max_overlap_unit, num_clusters);

grouping_comparison = [baseline_grouping_summary; hard_negative_grouping_summary];
disp(grouping_comparison);

figure;
tiledlayout(1, 2);

nexttile;
plot_grouping_result(baseline_grouping_summary, SUPPORT_CUTOFFS, ...
    "Baseline network");

nexttile;
plot_grouping_result(hard_negative_grouping_summary, SUPPORT_CUTOFFS, ...
    "Hard-negative network");

%% 12. Save everything needed to inspect or apply the final model

final_net = hard_negative_net;
final_feature_mean = hard_feature_mean;
final_feature_std = hard_feature_std;
final_grouping_summary = final_test_grouping_summary;

if isfile(save_file)
    delete(save_file);
end

save(save_file, ...
    "baseline_net", "baseline_layers", "baseline_options", ...
    "baseline_feature_mean", "baseline_feature_std", ...
    "baseline_pair_summary", "baseline_validation_cutoffs", ...
    "baseline_probability", "baseline_grouping_summary", ...
    "baseline_groups", "baseline_group_summaries", ...
    "baseline_training_grouping_summary", ...
    "baseline_validation_grouping_summary", ...
    "hard_negative_net", "hard_negative_layers", "hard_negative_options", ...
    "hard_feature_mean", "hard_feature_std", "hard_negative_rows", ...
    "new_hard_negative_rows", "hard_negative_pair_summary", ...
    "hard_negative_validation_cutoffs", "hard_negative_probability", ...
    "hard_negative_grouping_summary", "hard_negative_groups", ...
    "hard_negative_group_summaries", ...
    "hard_validation_grouping_summary", "selected_validation_row", ...
    "selected_probability_cutoff", "selected_support_cutoff", ...
    "final_test_grouping_summary", "final_test_groups", ...
    "final_test_group_summaries", "training_grouping_data", ...
    "validation_grouping_data", "test_grouping_data", ...
    "final_net", "final_feature_mean", "final_feature_std", ...
    "final_grouping_summary", "feature_names", ...
    "PROBABILITY_CUTOFFS", "SUPPORT_CUTOFFS", ...
    "HARD_NEGATIVE_PROBABILITY", "HARD_NEGATIVE_SUPPORT", ...
    "TRAIN_DONT_MERGE_FRACTION", "VALIDATION_DONT_MERGE_FRACTION", ...
    "grouping_comparison", "-v7.3");

fprintf("\nSaved the complete experiment to:\n%s\n", save_file);
fprintf("total script time %.1f seconds\n", toc(total_tic));

%% Helper functions
% The experiment ends above. The functions below only keep repeated
% calculations out of the main explanation.

function rows = rows_for_units(units, group_is_pure, group_unit, left_group, right_group)
    group_is_allowed = group_is_pure & ismember(group_unit, units(:));
    rows = find(group_is_allowed(left_group) & group_is_allowed(right_group));
end

function data = make_grouping_subset(units, starting_groups, group_is_pure, ...
        group_unit, left_group, right_group, max_overlap_unit)

    starting_group_ids = find(group_is_pure & ismember(group_unit, units(:)));
    old_to_new_group = zeros(numel(starting_groups), 1);
    old_to_new_group(starting_group_ids) = (1:numel(starting_group_ids)).';

    pair_is_in_subset = old_to_new_group(left_group) > 0 & ...
        old_to_new_group(right_group) > 0;
    pair_rows = find(pair_is_in_subset);

    groups = starting_groups(starting_group_ids);
    cluster_ids = [];
    for group_id = 1:numel(groups)
        cluster_ids = [cluster_ids; groups{group_id}(:)]; %#ok<AGROW>
    end

    data = struct();
    data.units = units(:);
    data.starting_group_ids = starting_group_ids;
    data.groups = groups;
    data.pair_rows = pair_rows;
    data.left_group = old_to_new_group(left_group(pair_rows));
    data.right_group = old_to_new_group(right_group(pair_rows));
    data.cluster_ids = cluster_ids;
    data.num_starting_groups = numel(groups);
    data.num_clusters = numel(cluster_ids);
    data.num_units = numel(unique(max_overlap_unit(cluster_ids)));

    expected_pairs = data.num_starting_groups * (data.num_starting_groups - 1) / 2;
    if numel(pair_rows) ~= expected_pairs
        error("A grouping subset does not contain every expected group pair.");
    end
end

function print_grouping_subset(name, data)
    fprintf("%-10s grouping subset: %4d units | %4d starting groups | %4d clusters\n", ...
        name, data.num_units, data.num_starting_groups, data.num_clusters);
end

function labels = pair_labels(rows, group_unit, left_group, right_group)
    labels = group_unit(left_group(rows)) == group_unit(right_group(rows));
end

function chosen_rows = sample_rows(all_rows, is_merge, dont_merge_fraction)
    merge_positions = find(is_merge);
    dont_merge_positions = find(~is_merge);
    merge_fraction = 1 - dont_merge_fraction;

    num_merge = numel(merge_positions);
    num_dont_merge = round(num_merge * dont_merge_fraction / merge_fraction);

    if num_dont_merge > numel(dont_merge_positions)
        num_dont_merge = numel(dont_merge_positions);
        num_merge = round(num_dont_merge * merge_fraction / dont_merge_fraction);
    end

    merge_positions = merge_positions(randperm(numel(merge_positions), num_merge));
    dont_merge_positions = dont_merge_positions(randperm(numel(dont_merge_positions), num_dont_merge));

    positions = [merge_positions; dont_merge_positions];
    positions = positions(randperm(numel(positions)));
    chosen_rows = all_rows(positions);
end

function print_row_counts(name, rows, group_unit, left_group, right_group)
    is_merge = pair_labels(rows, group_unit, left_group, right_group);
    fprintf("%-22s %7d rows | merge %6d | dont_merge %7d\n", ...
        name + ":", numel(rows), sum(is_merge), sum(~is_merge));
end

function counts = count_group_timestamps(groups, bp_filtered)
    timestamp_column = bp_filtered{:, "timestamps"};
    cluster_timestamps = cell(height(bp_filtered), 1);

    for cluster_id = 1:height(bp_filtered)
        timestamps = timestamp_column{cluster_id};
        if iscell(timestamps)
            timestamps = timestamps{1};
        end
        cluster_timestamps{cluster_id} = timestamps(:);
    end

    counts = zeros(numel(groups), 1);
    for group_id = 1:numel(groups)
        members = groups{group_id};
        group_timestamps = [];
        for member_id = 1:numel(members)
            group_timestamps = [group_timestamps; ...
                cluster_timestamps{members(member_id)}]; %#ok<AGROW>
        end
        counts(group_id) = numel(unique(group_timestamps));
    end
end

function distance = calculate_repwire_distance(groups, bp_filtered, left_group, right_group)
    config = spikesort_config();
    probe_locations = get_probe_xy();
    assembled_data = assemble_data_for_neural_net("rep_wire", bp_filtered, config);
    cluster_rep_wire = assembled_data{1};
    cluster_location = probe_locations(cluster_rep_wire, :);

    group_location = zeros(numel(groups), 2);
    for group_id = 1:numel(groups)
        group_location(group_id, :) = mean(cluster_location(groups{group_id}, :), 1);
    end

    difference = group_location(left_group, :) - group_location(right_group, :);
    distance = sqrt(sum(difference .^ 2, 2));
end

function X = feature_matrix(rows, timestamp_data, waveform_data, repwire_distance, ...
        group_cluster_count, group_timestamp_count, left_group, right_group, feature_names)

    values = struct();
    values.small_timestamp_overlap = timestamp_data.smaller_overlap_percent(rows);
    values.large_timestamp_overlap = timestamp_data.reciprocal_overlap_percent(rows);
    values.matched_timestamps = timestamp_data.matched_timestamps(rows);
    values.waveform_distance = waveform_data.waveform_distance(rows);
    values.repwire_distance = repwire_distance(rows);
    values.left_cluster_count = group_cluster_count(left_group(rows));
    values.right_cluster_count = group_cluster_count(right_group(rows));
    values.left_timestamp_count = group_timestamp_count(left_group(rows));
    values.right_timestamp_count = group_timestamp_count(right_group(rows));

    X = zeros(numel(rows), numel(feature_names));
    for feature_id = 1:numel(feature_names)
        X(:, feature_id) = values.(char(feature_names(feature_id)));
    end
end

function [X, feature_mean, feature_std] = normalize_training_data(X_raw)
    feature_mean = mean(X_raw, 1);
    feature_std = std(X_raw, 0, 1);
    feature_std(feature_std == 0) = 1;
    X = (X_raw - feature_mean) ./ feature_std;
end

function X = apply_normalization(X_raw, feature_mean, feature_std)
    X = (X_raw - feature_mean) ./ feature_std;
end

function layers = group_pair_layers(num_features)
    layers = [
        featureInputLayer(num_features)
        fullyConnectedLayer(16)
        reluLayer
        fullyConnectedLayer(8)
        reluLayer
        fullyConnectedLayer(2)
        softmaxLayer
    ];
end

function options = group_pair_training_options(X_validation, Y_validation, batch_size, max_epochs)
    options = trainingOptions("adam", ...
        MiniBatchSize=batch_size, ...
        Shuffle="every-epoch", ...
        ValidationData={X_validation, Y_validation}, ...
        Metrics="accuracy", ...
        Verbose=true, ...
        Plots="none", ...
        MaxEpochs=max_epochs);
end

function summary = evaluate_model(net, X_train, Y_train, X_validation, Y_validation, ...
        X_test_balanced, Y_test_balanced, X_test_natural, Y_test_natural, model_name)

    summary = [
        pair_metrics(net, X_train, Y_train, model_name + "_train", 0.50)
        pair_metrics(net, X_validation, Y_validation, model_name + "_validation", 0.50)
        pair_metrics(net, X_test_balanced, Y_test_balanced, model_name + "_test_balanced", 0.50)
        pair_metrics(net, X_test_natural, Y_test_natural, model_name + "_test_natural", 0.50)
    ];
end

function summary = evaluate_cutoffs(net, X, Y, cutoffs, split_name)
    summary = table();
    for cutoff_id = 1:numel(cutoffs)
        summary = [summary; pair_metrics(net, X, Y, split_name, cutoffs(cutoff_id))]; %#ok<AGROW>
    end
end

function result = pair_metrics(net, X, Y_true, split_name, probability_cutoff)
    scores = predict(net, X);
    predicted_merge = scores(:, 2) >= probability_cutoff;
    true_merge = Y_true == "merge";

    TP = sum(predicted_merge & true_merge);
    FP = sum(predicted_merge & ~true_merge);
    TN = sum(~predicted_merge & ~true_merge);
    FN = sum(~predicted_merge & true_merge);

    accuracy = (TP + TN) / numel(Y_true);
    precision = TP / max(TP + FP, 1);
    recall = TP / max(TP + FN, 1);
    false_merge_rate = FP / max(FP + TN, 1);
    false_skip_rate = FN / max(FN + TP, 1);

    result = table(string(split_name), probability_cutoff, size(X, 1), ...
        TP, FP, TN, FN, accuracy, precision, recall, false_merge_rate, ...
        false_skip_rate, 'VariableNames', {'split_name', 'probability_cutoff', ...
        'num_rows', 'TP', 'FP', 'TN', 'FN', 'accuracy', 'precision', ...
        'recall', 'false_merge_rate', 'false_skip_rate'});
end

function probability = score_all_pairs(net, timestamp_data, waveform_data, ...
        repwire_distance, group_cluster_count, group_timestamp_count, ...
        left_group, right_group, feature_names, feature_mean, feature_std, batch_size)

    score_tic = tic;
    num_pairs = numel(left_group);
    num_batches = ceil(num_pairs / batch_size);
    probability = zeros(num_pairs, 1);

    for batch_id = 1:num_batches
        first_row = (batch_id - 1) * batch_size + 1;
        last_row = min(batch_id * batch_size, num_pairs);
        rows = first_row:last_row;

        X = feature_matrix(rows, timestamp_data, waveform_data, repwire_distance, ...
            group_cluster_count, group_timestamp_count, left_group, right_group, feature_names);
        X = apply_normalization(X, feature_mean, feature_std);
        scores = predict(net, X);
        probability(rows) = scores(:, 2);

        fprintf("scored batch %d / %d, rows %d-%d, time %.1f sec\n", ...
            batch_id, num_batches, first_row, last_row, toc(score_tic));
    end
end

function hard_rows = harvest_hard_negatives(final_groups, final_group_summary, ...
        cluster_to_starting_group, group_is_pure, group_unit, train_units, ...
        left_group, right_group, num_starting_groups)

    num_pairs = numel(left_group);
    pair_numbers = (1:num_pairs).';
    pair_row_lookup = sparse([left_group; right_group], [right_group; left_group], ...
        [pair_numbers; pair_numbers], num_starting_groups, num_starting_groups);
    bad_groups = find(~final_group_summary.is_pure);
    hard_rows = [];

    for bad_id = 1:numel(bad_groups)
        clusters = final_groups{bad_groups(bad_id)};
        starting_group_ids = unique(cluster_to_starting_group(clusters));
        starting_group_ids = starting_group_ids(group_is_pure(starting_group_ids));

        for a = 1:numel(starting_group_ids) - 1
            for b = a + 1:numel(starting_group_ids)
                group_1 = starting_group_ids(a);
                group_2 = starting_group_ids(b);
                unit_1 = group_unit(group_1);
                unit_2 = group_unit(group_2);

                if unit_1 == unit_2
                    continue
                end

                if ~ismember(unit_1, train_units) || ~ismember(unit_2, train_units)
                    continue
                end

                row = full(pair_row_lookup(group_1, group_2));

                if row > 0
                    hard_rows(end + 1, 1) = row; %#ok<AGROW>
                end
            end
        end
    end

    hard_rows = unique(hard_rows);
end

function [summary, all_groups, all_group_summaries] = test_grouping_rules( ...
        model_name, starting_groups, left_group, right_group, probability, ...
        probability_cutoffs, support_cutoffs, max_overlap_unit, num_clusters)

    num_starting_groups = numel(starting_groups);
    probability_matrix = zeros(num_starting_groups, num_starting_groups, "single");
    matrix_rows = sub2ind([num_starting_groups, num_starting_groups], left_group, right_group);
    probability_matrix(matrix_rows) = single(probability);
    probability_matrix = probability_matrix + probability_matrix.';
    probability_matrix(1:num_starting_groups + 1:end) = 1;

    summary = table();
    all_groups = {};
    all_group_summaries = {};

    for probability_id = 1:numel(probability_cutoffs)
        probability_cutoff = probability_cutoffs(probability_id);
        candidate_rows = find(probability >= probability_cutoff);

        fprintf("\nprobability %.4f starts with %d candidate links\n", ...
            probability_cutoff, numel(candidate_rows));

        for support_id = 1:numel(support_cutoffs)
            support_cutoff = support_cutoffs(support_id);

            [groups, safe_merges] = make_safe_groups(starting_groups, left_group, ...
                right_group, probability, probability_matrix, candidate_rows, ...
                probability_cutoff, support_cutoff);

            group_summary = summarize_groups(groups, max_overlap_unit);
            unit_summary = summarize_units(groups, group_summary.is_pure, max_overlap_unit);

            all_groups{end + 1, 1} = groups; %#ok<AGROW>
            all_group_summaries{end + 1, 1} = group_summary; %#ok<AGROW>

            row = grouping_summary_row(model_name, probability_cutoff, ...
                support_cutoff, numel(candidate_rows), safe_merges, groups, ...
                group_summary, unit_summary, num_clusters);
            summary = [summary; row]; %#ok<AGROW>

            fprintf("prob %.4f | support %.2f | merges %4d | groups %4d | fully pure %.2f%% | mean purity %.2f%% | clusters pure %.2f%% | bad %d\n", ...
                probability_cutoff, support_cutoff, safe_merges, row.num_groups, ...
                row.fully_pure_group_percent, row.mean_group_purity_percent, ...
                row.clusters_in_pure_percent, row.contaminated_groups);
        end
    end
end

function selected_row = choose_validation_policy(summary)
    % Purity comes first. If more than one rule creates no contaminated
    % validation groups, choose the one with the fewest remaining groups.
    clean_rows = find(summary.contaminated_groups == 0);

    if ~isempty(clean_rows)
        ranking = [summary.num_groups(clean_rows), ...
            -summary.clusters_in_pure_percent(clean_rows)];
        [~, order] = sortrows(ranking, [1 2]);
        selected_id = clean_rows(order(1));
        selected_row = summary(selected_id, :);
        return
    end

    % This fallback is used only if every tested rule contaminates at least
    % one validation group.
    warning("No validation policy produced zero contaminated groups. Selecting the safest available rule.");
    ranking = [summary.contaminated_groups, ...
        -summary.clusters_in_pure_percent, ...
        -summary.mean_group_purity_percent, summary.num_groups];
    [~, order] = sortrows(ranking, [1 2 3 4]);
    selected_id = order(1);
    selected_row = summary(selected_id, :);
end

function [groups, num_merges] = make_safe_groups(starting_groups, left_group, ...
        right_group, probability, probability_matrix, candidate_rows, ...
        probability_cutoff, support_cutoff)

    num_starting_groups = numel(starting_groups);
    component_for_group = (1:num_starting_groups).';
    component_members = num2cell((1:num_starting_groups).');
    component_is_alive = true(num_starting_groups, 1);
    num_merges = 0;

    [~, order] = sort(probability(candidate_rows), "descend");
    candidate_rows = candidate_rows(order);

    for candidate_id = 1:numel(candidate_rows)
        row = candidate_rows(candidate_id);
        left_component = component_for_group(left_group(row));
        right_component = component_for_group(right_group(row));

        if left_component == right_component
            continue
        end

        left_members = component_members{left_component};
        right_members = component_members{right_component};
        cross_probabilities = probability_matrix(left_members, right_members);
        cross_support = mean(cross_probabilities(:) >= probability_cutoff);

        if cross_support >= support_cutoff
            component_members{left_component} = [left_members(:); right_members(:)];
            component_members{right_component} = [];
            component_for_group(right_members) = left_component;
            component_is_alive(right_component) = false;
            num_merges = num_merges + 1;
        end
    end

    alive_components = find(component_is_alive);
    groups = cell(numel(alive_components), 1);

    for final_group_id = 1:numel(alive_components)
        starting_group_ids = component_members{alive_components(final_group_id)};
        clusters = [];
        for member_id = 1:numel(starting_group_ids)
            clusters = [clusters; starting_groups{starting_group_ids(member_id)}(:)]; %#ok<AGROW>
        end
        groups{final_group_id} = unique(clusters);
    end
end

function row = grouping_summary_row(model_name, probability_cutoff, support_cutoff, ...
        candidate_links, safe_merges, groups, group_summary, unit_summary, num_clusters)

    num_groups = numel(groups);
    num_unique_units = height(unit_summary);
    groups_per_unit_ratio = num_groups / max(num_unique_units, 1);
    pure_groups = sum(group_summary.is_pure);
    fully_pure_group_percent = 100 * pure_groups / num_groups;
    mean_group_purity_percent = 100 * mean(group_summary.purity);
    clusters_in_pure_percent = 100 * ...
        sum(group_summary.group_size(group_summary.is_pure)) / num_clusters;
    contaminated_groups = sum(~group_summary.is_pure);
    largest_group_size = max(group_summary.group_size);
    fragmented_units = sum(unit_summary.groups_with_unit > 1);
    perfectly_contained_units = sum(unit_summary.perfectly_contained);
    units_with_clean_group = sum(unit_summary.clean_group_count > 0);

    row = table(string(model_name), probability_cutoff, support_cutoff, ...
        candidate_links, safe_merges, num_groups, pure_groups, ...
        num_unique_units, groups_per_unit_ratio, ...
        fully_pure_group_percent, mean_group_purity_percent, ...
        clusters_in_pure_percent, contaminated_groups, largest_group_size, ...
        fragmented_units, perfectly_contained_units, units_with_clean_group, ...
        'VariableNames', {'model_name', 'probability_cutoff', 'support_cutoff', ...
        'candidate_links', 'safe_merges', 'num_groups', 'pure_groups', ...
        'num_unique_units', 'groups_per_unit_ratio', ...
        'fully_pure_group_percent', 'mean_group_purity_percent', ...
        'clusters_in_pure_percent', 'contaminated_groups', 'largest_group_size', ...
        'fragmented_units', 'perfectly_contained_units', 'units_with_clean_group'});
end

function group_summary = summarize_groups(groups, max_overlap_unit)
    num_groups = numel(groups);
    group_id = (1:num_groups).';
    group_size = zeros(num_groups, 1);
    num_units = zeros(num_groups, 1);
    dominant_unit = nan(num_groups, 1);
    purity = zeros(num_groups, 1);
    is_pure = false(num_groups, 1);
    unit_list = cell(num_groups, 1);

    for group_id_here = 1:num_groups
        units = max_overlap_unit(groups{group_id_here});
        unique_units = unique(units);
        unit_counts = zeros(numel(unique_units), 1);

        for unit_id = 1:numel(unique_units)
            unit_counts(unit_id) = sum(units == unique_units(unit_id));
        end

        [largest_count, largest_id] = max(unit_counts);
        group_size(group_id_here) = numel(groups{group_id_here});
        num_units(group_id_here) = numel(unique_units);
        dominant_unit(group_id_here) = unique_units(largest_id);
        purity(group_id_here) = largest_count / group_size(group_id_here);
        is_pure(group_id_here) = num_units(group_id_here) == 1;
        unit_list{group_id_here} = unique_units(:).';
    end

    group_summary = table(group_id, group_size, num_units, dominant_unit, ...
        purity, is_pure, unit_list);
end

function unit_summary = summarize_units(groups, group_is_pure, max_overlap_unit)
    included_clusters = [];
    for group_id = 1:numel(groups)
        included_clusters = [included_clusters; groups{group_id}(:)]; %#ok<AGROW>
    end

    included_cluster = false(numel(max_overlap_unit), 1);
    included_cluster(included_clusters) = true;
    unique_units = unique(max_overlap_unit(included_clusters));
    cluster_to_group = zeros(numel(max_overlap_unit), 1);

    for group_id = 1:numel(groups)
        cluster_to_group(groups{group_id}) = group_id;
    end

    unit_id = unique_units(:);
    groups_with_unit = zeros(numel(unique_units), 1);
    clean_group_count = zeros(numel(unique_units), 1);
    perfectly_contained = false(numel(unique_units), 1);

    for unit_index = 1:numel(unique_units)
        unit_belongs_here = included_cluster & ...
            max_overlap_unit == unique_units(unit_index);
        touched_groups = unique(cluster_to_group(unit_belongs_here));
        groups_with_unit(unit_index) = numel(touched_groups);
        clean_group_count(unit_index) = sum(group_is_pure(touched_groups));
        perfectly_contained(unit_index) = groups_with_unit(unit_index) == 1 && ...
            clean_group_count(unit_index) == 1;
    end

    unit_summary = table(unit_id, groups_with_unit, clean_group_count, perfectly_contained);
end

function plot_grouping_result(summary, support_cutoffs, plot_title)
    hold on
    for support_id = 1:numel(support_cutoffs)
        rows = summary.support_cutoff == support_cutoffs(support_id);
        plot(summary.num_groups(rows), summary.mean_group_purity_percent(rows), ...
            "-o", "LineWidth", 1.5, ...
            "DisplayName", sprintf("support %.2f", support_cutoffs(support_id)));
    end

    xline(349, "--", "349 units", "LineWidth", 1.5);
    plot(349, 100, "p", "MarkerSize", 14, ...
        "MarkerFaceColor", "red", "MarkerEdgeColor", "black", ...
        "DisplayName", "ideal reference");
    xlabel("number of groups");
    ylabel("mean group purity (%)");
    title(plot_title);
    legend("Location", "best");
    grid on
    hold off
end
