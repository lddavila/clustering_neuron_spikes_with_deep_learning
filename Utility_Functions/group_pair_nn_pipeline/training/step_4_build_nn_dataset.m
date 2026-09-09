%%
% Build the group-pair dataset for a merge / dont-merge neural network.
%
% This does not train the neural network yet.
% It only prepares the tables that the network will use later.
%
% Each row is one comparison:
%
%   group A vs group B
%
% So the "data points" for the neural network are not individual clusters and
% not individual groups. The data points are pairs of groups.
%
% The label is:
%
%   1 = same Max_Overlap_Unit
%   0 = different Max_Overlap_Unit
%
% The split is done by Max_Overlap_Unit first, not by random pair rows.
% This helps stop the network from seeing the same unit in training and testing.
%
% Max_Overlap_Unit is only used to make the label and to split the units.
% It is not one of the input features.

clear
clc

total_tic = tic;
rng("default");

script_folder = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(script_folder)));
addpath(genpath(repo_root), "-begin");

remove_conflicts_file = fullfile(repo_root, "Default_Results_Dir", "remove_conflicts_only_result.mat");
timestamp_file = fullfile(repo_root, "Default_Results_Dir", "simple_timestamp_reciprocal_grouping_result.mat");
waveform_file = fullfile(repo_root, "Default_Results_Dir", "simple_euclidean_only_grouping_result.mat");
save_file = fullfile(repo_root, "Default_Results_Dir", "group_pair_nn_dataset.mat");

TRAIN_FRACTION = 0.60;
VALIDATION_FRACTION = 0.20;
TEST_FRACTION = 0.20;

if ~isfile(remove_conflicts_file)
    error("Run step_1_make_remove_conflicts_groups.m first.");
end

if ~isfile(timestamp_file)
    error("Run step_2_compute_timestamp_features.m first.");
end

if ~isfile(waveform_file)
    error("Run step_3_compute_waveform_features.m first.");
end

fprintf("\nLoading saved data...\n");
load_tic = tic;

% remove_conflicts_file has the clean starting groups.
% timestamp_file has the timestamp overlap numbers we already computed.
% waveform_file has the Euclidean waveform distances we already computed.
% This script reuses those saved values instead of recalculating the slow parts.
S = load(remove_conflicts_file, "remove_conflicts_groups", "bp_filtered", "group_summary");
T = load(timestamp_file, "smaller_overlap_percent", "reciprocal_overlap_percent", ...
    "matched_timestamps", "smaller_timestamp_count", "larger_timestamp_count", "group_a", "group_b");
W = load(waveform_file, "waveform_distance", "group_a", "group_b");

old_groups = S.remove_conflicts_groups;
bp_filtered = S.bp_filtered;
group_summary = S.group_summary;

if ~isequal(T.group_a, W.group_a) || ~isequal(T.group_b, W.group_b)
    % This matters because row 1000 in the timestamp file must describe the
    % same group pair as row 1000 in the waveform file.
    error("The timestamp and waveform pair lists do not match.");
end

group_a = T.group_a;
group_b = T.group_b;

num_clusters = height(bp_filtered);
num_old_groups = numel(old_groups);
num_pairs = numel(group_a);

fprintf("clusters: %d\n", num_clusters);
fprintf("starting groups: %d\n", num_old_groups);
fprintf("saved group pairs: %d\n", num_pairs);
fprintf("loading took %.1f seconds\n", toc(load_tic));

%% make group-level information

fprintf("\nMaking group-level information...\n");
setup_tic = tic;

% group_summary comes from remove_conflicts
% this is the grouping strategy taht gives us very high purity (+99%) but a lot
% of groups (about 3000)
% For the first neural-network dataset, I only use pure groups because they have
% a clean answer key. If a group is already contaminated, it is hard to say what
% unit that group really represents.
group_is_pure = group_summary.is_pure;
group_unit = group_summary.dominant_unit;
group_cluster_count = group_summary.group_size;

% Timestamp count means how many unique timestamps are inside each group.
% This is different from group_cluster_count:
%
%   group_cluster_count    = how many clusters are in the group
%   group_timestamp_count  = how many spike timestamps are in the group
%
% The timestamp count can help because a group with thousands of spikes gives
% stronger evidence than a group with only a few spikes.
timestamps_col = bp_filtered{:, "timestamps"};
cluster_timestamps = cell(num_clusters, 1);

for i = 1:num_clusters
    ts = timestamps_col{i};
    if iscell(ts)
        ts = ts{1};
    end
    cluster_timestamps{i} = ts(:);
end

group_timestamp_count = zeros(num_old_groups, 1);

for g = 1:num_old_groups
    members = old_groups{g};
    group_ts = [];

    for j = 1:numel(members)
        group_ts = [group_ts; cluster_timestamps{members(j)}]; %#ok<AGROW>
    end

    group_timestamp_count(g) = numel(unique(group_ts));
end

% The old example network uses rep-wire distance.
% For a group, I use the average location of the clusters in that group.
%
% This is a simple group version of the feature in:
% train_most_simplified_group_or_dont_nn.m
%
% A small repwire distance means the two groups are physically close on the
% probe. A large repwire distance means they are far apart.
config = spikesort_config();
locations = get_probe_xy();
assembled = assemble_data_for_neural_net(["rep_wire"], bp_filtered, config);
cluster_rep_wire = assembled{1};
cluster_location = locations(cluster_rep_wire, :);

group_location = zeros(num_old_groups, 2);

for g = 1:num_old_groups
    members = old_groups{g};
    group_location(g, :) = mean(cluster_location(members, :), 1);
end

repwire_distance = sqrt(sum((group_location(group_a, :) - group_location(group_b, :)).^2, 2));

fprintf("group setup took %.1f seconds\n", toc(setup_tic));

%% split units first

fprintf("\nSplitting units into train / validation / test...\n");
split_tic = tic;

% This is the most important anti-leakage step.
%
% I split the units first, then I make group-pair rows inside each split.
% I dont make all pair rows first and randomly split the rows.
%
% If I randomly split rows, the same unit could appear in both training and
% testing. Then the network could partly memorize that unit instead of learning
% a general merge rule.
pure_units = unique(group_unit(group_is_pure));
pure_units = pure_units(:);
pure_units = pure_units(randperm(numel(pure_units)));

num_units = numel(pure_units);
num_train_units = round(TRAIN_FRACTION * num_units);
num_validation_units = round(VALIDATION_FRACTION * num_units);
num_test_units = num_units - num_train_units - num_validation_units;

train_units = pure_units(1:num_train_units);
validation_units = pure_units(num_train_units + 1:num_train_units + num_validation_units);
test_units = pure_units(num_train_units + num_validation_units + 1:end);

fprintf("pure units used for splitting: %d\n", num_units);
fprintf("train units:      %d\n", numel(train_units));
fprintf("validation units: %d\n", numel(validation_units));
fprintf("test units:       %d\n", numel(test_units));
fprintf("split took %.1f seconds\n", toc(split_tic));

%% build the pair tables

fprintf("\nBuilding pair tables...\n");
table_tic = tic;

% These are the pair-row indexes for each split.
% A pair row is one comparison:
%
%   group_a(row) vs group_b(row)
%
% The pair is allowed in a split only if both groups belong to units from that
% split.
train_pair_rows = get_pair_rows_for_units(train_units, group_is_pure, group_unit, group_a, group_b);
validation_pair_rows = get_pair_rows_for_units(validation_units, group_is_pure, group_unit, group_a, group_b);
test_pair_rows = get_pair_rows_for_units(test_units, group_is_pure, group_unit, group_a, group_b);

% The label is the answer for supervised learning.
%
%   same unit      -> label 1 -> merge
%   different unit -> label 0 -> dont merge
%
% The network will see the label during training, but it will not see the unit
% IDs as input features.
train_label = group_unit(group_a(train_pair_rows)) == group_unit(group_b(train_pair_rows));
validation_label = group_unit(group_a(validation_pair_rows)) == group_unit(group_b(validation_pair_rows));
test_label = group_unit(group_a(test_pair_rows)) == group_unit(group_b(test_pair_rows));

% Most possible group pairs are dont-merge pairs.
% If I trained on the natural training table, the network could cheat by saying
% dont merge almost all the time.
%
% So train_table and validation_table are balanced:
%
%   50% merge
%   50% dont merge
%
% The natural test table is still saved because it represents the real
% imbalanced situation.
balanced_train_pair_rows = balance_pair_rows(train_pair_rows, train_label);
balanced_validation_pair_rows = balance_pair_rows(validation_pair_rows, validation_label);
balanced_test_pair_rows = balance_pair_rows(test_pair_rows, test_label);

train_table = make_pair_table_from_rows(balanced_train_pair_rows, "train", ...
    group_unit, group_a, group_b, T, W, repwire_distance, ...
    group_cluster_count, group_timestamp_count);

validation_table = make_pair_table_from_rows(balanced_validation_pair_rows, "validation", ...
    group_unit, group_a, group_b, T, W, repwire_distance, ...
    group_cluster_count, group_timestamp_count);

test_table_natural = make_pair_table_from_rows(test_pair_rows, "test", ...
    group_unit, group_a, group_b, T, W, repwire_distance, ...
    group_cluster_count, group_timestamp_count);

test_table_balanced = make_pair_table_from_rows(balanced_test_pair_rows, "test_balanced", ...
    group_unit, group_a, group_b, T, W, repwire_distance, ...
    group_cluster_count, group_timestamp_count);

fprintf("natural train rows:      %d | merge %d | dont merge %d\n", ...
    numel(train_pair_rows), sum(train_label), sum(~train_label));
fprintf("balanced train rows:     %d | merge %d | dont merge %d\n", ...
    height(train_table), sum(train_table.label), sum(~train_table.label));

fprintf("natural validation rows: %d | merge %d | dont merge %d\n", ...
    numel(validation_pair_rows), sum(validation_label), sum(~validation_label));
fprintf("balanced validation rows:%d | merge %d | dont merge %d\n", ...
    height(validation_table), sum(validation_table.label), sum(~validation_table.label));

fprintf("natural test rows:       %d | merge %d | dont merge %d\n", ...
    height(test_table_natural), sum(test_label), sum(~test_label));
fprintf("balanced test rows:      %d | merge %d | dont merge %d\n", ...
    height(test_table_balanced), sum(test_table_balanced.label), sum(~test_table_balanced.label));

fprintf("table build took %.1f seconds\n", toc(table_tic));

%% print quick feature summaries

% These are the only columns that should go into the neural network as inputs.
%
% In plain words:
%
% small_timestamp_overlap:
%   how much of the smaller group matches the bigger group
%
% large_timestamp_overlap:
%   how much of the bigger group is covered too
%
% matched_timestamps:
%   the raw number of timestamp matches
%
% waveform_distance:
%   how different the average waveforms are
%
% repwire_distance:
%   how physically far apart the groups are on the probe
%
% left/right cluster count:
%   how many clusters are inside each group
%
% left/right timestamp count:
%   how many unique spike timestamps are inside each group
feature_columns = [
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

% These columns are useful for checking and understanding the table, but they
% should not be used as neural-network inputs.
%
% left_unit and right_unit would leak the answer.
checking_columns = [
    "left_group"
    "right_group"
    "left_unit"
    "right_unit"
    "split_name"
    "label"
];

fprintf("\nAllowed neural-network feature columns\n");
disp(feature_columns);

fprintf("\nChecking columns saved for understanding, but do NOT train on them\n");
disp(checking_columns);

fprintf("\nTraining feature summary\n");
train_feature_summary = summarize_features(train_table, feature_columns);
disp(train_feature_summary);

%% save

if isfile(save_file)
    delete(save_file);
end

save(save_file, "train_table", "validation_table", "test_table_natural", ...
    "test_table_balanced", "feature_columns", "checking_columns", "train_units", "validation_units", ...
    "test_units", "TRAIN_FRACTION", "VALIDATION_FRACTION", "TEST_FRACTION", "-v7.3");

fprintf("\nsaved dataset to:\n%s\n", save_file);
fprintf("total time %.1f seconds\n", toc(total_tic));

%% notes
%
% train_table and validation_table are balanced 50/50.
%
% test_table_natural keeps the natural imbalance. This is useful because in real
% life most group pairs are dont-merge pairs.
%
% test_table_balanced is also saved because it is easier to check whether the
% model understands both classes.
%
% The actual input features for the neural network are in feature_columns.
% Do not train on Max_Overlap_Unit, unit_list, purity, is_pure, num_units,
% left_unit, or right_unit.

%% local helper functions

function pair_rows = get_pair_rows_for_units(units_for_split, group_is_pure, group_unit, group_a, group_b)
    units_for_split = units_for_split(:);

    % Keep only pure groups whose unit belongs to this split.
    % Then keep only pair rows where both groups are in that split.
    groups_in_split = group_is_pure & ismember(group_unit, units_for_split);
    pair_rows = find(groups_in_split(group_a) & groups_in_split(group_b));
end

function pair_table = make_pair_table_from_rows(pair_rows, split_name, ...
    group_unit, group_a, group_b, T, W, repwire_distance, ...
    group_cluster_count, group_timestamp_count)
    % Turn saved pair-row indexes into a readable table.
    % This is where the actual feature columns get assembled.

    left_group = group_a(pair_rows);
    right_group = group_b(pair_rows);
    left_unit = group_unit(left_group);
    right_unit = group_unit(right_group);
    label = left_unit == right_unit;

    % Timestamp features.
    % These came from simple_timestamp_reciprocal_grouping.m.
    small_timestamp_overlap = T.smaller_overlap_percent(pair_rows);
    large_timestamp_overlap = T.reciprocal_overlap_percent(pair_rows);
    matched_timestamps = T.matched_timestamps(pair_rows);
    smaller_timestamp_count = T.smaller_timestamp_count(pair_rows);
    larger_timestamp_count = T.larger_timestamp_count(pair_rows);

    % Waveform and location features.
    % waveform_distance came from simple_euclidean_only_grouping.m.
    % repwire_distance was calculated in this script.
    waveform_distance = W.waveform_distance(pair_rows);
    repwire_distance_here = repwire_distance(pair_rows);

    % Size / reliability features.
    left_cluster_count = group_cluster_count(left_group);
    right_cluster_count = group_cluster_count(right_group);
    left_timestamp_count = group_timestamp_count(left_group);
    right_timestamp_count = group_timestamp_count(right_group);
    split_name_col = repmat(string(split_name), numel(pair_rows), 1);

    pair_table = table(split_name_col, left_group, right_group, left_unit, right_unit, label, ...
        small_timestamp_overlap, large_timestamp_overlap, matched_timestamps, ...
        smaller_timestamp_count, larger_timestamp_count, waveform_distance, ...
        repwire_distance_here, left_cluster_count, right_cluster_count, ...
        left_timestamp_count, right_timestamp_count);

    pair_table.Properties.VariableNames{1} = 'split_name';
    pair_table.Properties.VariableNames{13} = 'repwire_distance';
end

function balanced_pair_rows = balance_pair_rows(pair_rows, label)
    % Pick the same number of merge and dont-merge rows.
    % This is only for train/validation and the optional balanced test table.

    merge_rows = find(label);
    dont_merge_rows = find(~label);

    num_to_use = min(numel(merge_rows), numel(dont_merge_rows));

    if num_to_use == 0
        balanced_pair_rows = pair_rows([]);
        return
    end

    merge_rows = merge_rows(randperm(numel(merge_rows), num_to_use));
    dont_merge_rows = dont_merge_rows(randperm(numel(dont_merge_rows), num_to_use));

    chosen_rows = [merge_rows; dont_merge_rows];
    chosen_rows = chosen_rows(randperm(numel(chosen_rows)));

    balanced_pair_rows = pair_rows(chosen_rows);
end

function feature_summary = summarize_features(input_table, feature_columns)
    % Print simple means and medians for merge vs dont-merge rows.
    % This is just a sanity check to see whether the features separate the two
    % classes at all.

    merge_rows = input_table.label;
    dont_merge_rows = ~input_table.label;

    merge_mean = zeros(numel(feature_columns), 1);
    dont_merge_mean = zeros(numel(feature_columns), 1);
    merge_median = zeros(numel(feature_columns), 1);
    dont_merge_median = zeros(numel(feature_columns), 1);

    for i = 1:numel(feature_columns)
        values = input_table{:, feature_columns(i)};

        merge_mean(i) = mean(values(merge_rows));
        dont_merge_mean(i) = mean(values(dont_merge_rows));
        merge_median(i) = median(values(merge_rows));
        dont_merge_median(i) = median(values(dont_merge_rows));
    end

    feature_summary = table(feature_columns, merge_mean, dont_merge_mean, ...
        merge_median, dont_merge_median);
end
