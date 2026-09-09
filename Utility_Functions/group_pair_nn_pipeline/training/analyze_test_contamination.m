%% Analyze contamination in the final held-out test groups
% This script only reads the saved experiment. It does not train the network
% or change the selected probability and support cutoffs.
%
% groups_per_unit_ratio = number of final groups / number of unique units
% A value above 1 means there are extra fragments. A value below 1 means
% that merges or missing units have reduced the count. A value near 1 does
% not prove that the groups are correct, so purity is still needed.

clear
clc

total_tic = tic;

script_folder = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(script_folder)));
addpath(genpath(repo_root), "-begin");

results_dir = fullfile(repo_root, "Default_Results_Dir");
experiment_file = fullfile(results_dir, "group_pair_nn_clear_experiment_result.mat");
remove_conflicts_file = fullfile(results_dir, "remove_conflicts_only_result.mat");
timestamp_file = fullfile(results_dir, "simple_timestamp_reciprocal_grouping_result.mat");
waveform_file = fullfile(results_dir, "simple_euclidean_only_grouping_result.mat");
save_file = fullfile(results_dir, "final_test_contamination_analysis.mat");
figure_file = fullfile(results_dir, "final_test_group_unit_map.png");

required_files = {experiment_file, remove_conflicts_file, timestamp_file, waveform_file};
if any(~cellfun(@isfile, required_files))
    error("One or more saved result files are missing.");
end

fprintf("\nLoading saved held-out result...\n");
load_tic = tic;

E = load(experiment_file, "final_test_groups", "final_test_group_summaries", ...
    "test_grouping_data", "hard_negative_probability", ...
    "selected_probability_cutoff", "selected_support_cutoff");
S = load(remove_conflicts_file, "bp_filtered");
T = load(timestamp_file, "smaller_overlap_percent", ...
    "reciprocal_overlap_percent", "matched_timestamps");
W = load(waveform_file, "waveform_distance");

bp_filtered = S.bp_filtered;
max_overlap_unit = bp_filtered{:, "Max_Overlap_Unit"};
starting_groups = E.test_grouping_data.groups;
final_groups = E.final_test_groups;
if isscalar(final_groups) && iscell(final_groups{1})
    final_groups = final_groups{1};
end
final_group_summary = E.final_test_group_summaries{1};

num_starting_groups = numel(starting_groups);
num_final_groups = numel(final_groups);
num_test_clusters = E.test_grouping_data.num_clusters;
num_unique_units = E.test_grouping_data.num_units;
probability_cutoff = E.selected_probability_cutoff;
support_cutoff = E.selected_support_cutoff;

fprintf("test units:              %d\n", num_unique_units);
fprintf("test clusters:           %d\n", num_test_clusters);
fprintf("starting groups:         %d\n", num_starting_groups);
fprintf("final groups:            %d\n", num_final_groups);
fprintf("probability cutoff:      %.3f\n", probability_cutoff);
fprintf("support cutoff:          %.2f\n", support_cutoff);
fprintf("loading took %.1f seconds\n", toc(load_tic));

%% Check that the saved grouping is internally consistent

fprintf("\nChecking the saved result...\n");

test_clusters = E.test_grouping_data.cluster_ids(:);
final_clusters = [];
for group_id = 1:num_final_groups
    final_clusters = [final_clusters; final_groups{group_id}(:)]; %#ok<AGROW>
end

missing_clusters = setdiff(test_clusters, final_clusters);
extra_clusters = setdiff(final_clusters, test_clusters);
duplicate_cluster_count = numel(final_clusters) - numel(unique(final_clusters));

if ~isempty(missing_clusters) || ~isempty(extra_clusters) || duplicate_cluster_count > 0
    error("The final groups do not contain each test cluster exactly once.");
end

starting_group_is_pure = false(num_starting_groups, 1);
starting_group_unit = nan(num_starting_groups, 1);
cluster_to_starting_group = zeros(height(bp_filtered), 1);

for group_id = 1:num_starting_groups
    members = starting_groups{group_id};
    units = unique(max_overlap_unit(members));
    starting_group_is_pure(group_id) = isscalar(units);
    if isscalar(units)
        starting_group_unit(group_id) = units;
    end
    cluster_to_starting_group(members) = group_id;
end

if ~all(starting_group_is_pure)
    error("The held-out grouping contains a starting group that was not pure.");
end

fprintf("Every test cluster appears once, and every starting group is pure.\n");

%% Add the group-count ratio and quantify cluster-level corruption

group_sizes = final_group_summary.group_size;
group_is_pure = final_group_summary.is_pure;
dominant_cluster_count = zeros(num_final_groups, 1);
minority_cluster_count = zeros(num_final_groups, 1);

test_units = unique(max_overlap_unit(test_clusters));
group_unit_matrix = zeros(num_final_groups, num_unique_units);

for group_id = 1:num_final_groups
    units = max_overlap_unit(final_groups{group_id});
    [unit_list, ~, unit_position] = unique(units);
    unit_counts = accumarray(unit_position, 1);
    dominant_cluster_count(group_id) = max(unit_counts);
    minority_cluster_count(group_id) = group_sizes(group_id) - ...
        dominant_cluster_count(group_id);

    for unit_id = 1:numel(unit_list)
        column = find(test_units == unit_list(unit_id), 1);
        group_unit_matrix(group_id, column) = unit_counts(unit_id);
    end
end

bad_group_ids = find(~group_is_pure);
pure_groups = sum(group_is_pure);
clusters_in_pure_groups = sum(group_sizes(group_is_pure));
clusters_exposed_to_contamination = sum(group_sizes(~group_is_pure));
minority_clusters = sum(minority_cluster_count);
contaminated_groups = numel(bad_group_ids);

starting_groups_per_unit_ratio = num_starting_groups / num_unique_units;
groups_per_unit_ratio = num_final_groups / num_unique_units;
group_count_error = num_final_groups - num_unique_units;
fully_pure_group_percent = 100 * pure_groups / num_final_groups;
mean_group_purity_percent = 100 * mean(final_group_summary.purity);
clusters_in_pure_percent = 100 * clusters_in_pure_groups / num_test_clusters;
clusters_exposed_percent = 100 * clusters_exposed_to_contamination / num_test_clusters;
minority_cluster_corruption_percent = 100 * minority_clusters / num_test_clusters;

overall_summary = table(num_unique_units, num_starting_groups, ...
    starting_groups_per_unit_ratio, num_final_groups, groups_per_unit_ratio, ...
    group_count_error, pure_groups, fully_pure_group_percent, ...
    mean_group_purity_percent, clusters_in_pure_percent, ...
    contaminated_groups, clusters_exposed_to_contamination, ...
    clusters_exposed_percent, minority_clusters, ...
    minority_cluster_corruption_percent);

fprintf("\nFinal held-out contamination summary\n");
disp(overall_summary);

fprintf("The ratio is close to 1, but it must be read together with contamination.\n");
fprintf("%d clusters are inside mixed groups, while %d clusters have minority unit labels.\n", ...
    clusters_exposed_to_contamination, minority_clusters);

%% Print the three contaminated groups and their cluster members

bad_group_summary = final_group_summary(bad_group_ids, :);
bad_group_summary.dominant_cluster_count = dominant_cluster_count(bad_group_ids);
bad_group_summary.minority_cluster_count = minority_cluster_count(bad_group_ids);
bad_group_summary.exposed_cluster_percent = ...
    100 * bad_group_summary.group_size / num_test_clusters;

fprintf("\nContaminated final groups\n");
disp(bad_group_summary(:, ["group_id", "group_size", "num_units", ...
    "dominant_unit", "dominant_cluster_count", "minority_cluster_count", ...
    "purity", "unit_list"]));

accuracy_column = find(strcmpi(bp_filtered.Properties.VariableNames, "accuracy"), 1);
timestamp_column = find(strcmpi(bp_filtered.Properties.VariableNames, "timestamps"), 1);
bad_cluster_details = table();

for bad_id = 1:numel(bad_group_ids)
    group_id = bad_group_ids(bad_id);
    members = final_groups{group_id}(:);
    source_local_group = cluster_to_starting_group(members);
    source_full_group = E.test_grouping_data.starting_group_ids(source_local_group);
    unit = max_overlap_unit(members);
    is_dominant_unit = unit == final_group_summary.dominant_unit(group_id);
    cluster_accuracy = nan(numel(members), 1);
    timestamp_count = nan(numel(members), 1);

    if ~isempty(accuracy_column)
        cluster_accuracy = bp_filtered{members, accuracy_column};
    end

    if ~isempty(timestamp_column)
        timestamp_cells = bp_filtered{members, timestamp_column};
        for cluster_id = 1:numel(members)
            timestamps = timestamp_cells{cluster_id};
            while iscell(timestamps)
                timestamps = timestamps{1};
            end
            timestamp_count(cluster_id) = numel(timestamps);
        end
    end

    final_group_id = repmat(group_id, numel(members), 1);
    rows = table(final_group_id, members, source_local_group, ...
        source_full_group, unit, is_dominant_unit, cluster_accuracy, ...
        timestamp_count, 'VariableNames', ["final_group_id", "cluster_index", ...
        "test_starting_group", "full_remove_conflicts_group", "unit", ...
        "is_dominant_unit", "cluster_accuracy", "timestamp_count"]);
    bad_cluster_details = [bad_cluster_details; rows]; %#ok<AGROW>
end

fprintf("\nMinority clusters responsible for contamination\n");
disp(bad_cluster_details(~bad_cluster_details.is_dominant_unit, :));
fprintf("The complete cluster table is saved in bad_cluster_details.\n");

%% Replay the locked grouping rule and record accepted cross-unit links

fprintf("\nReplaying the locked grouping rule to find the bad links...\n");

left_group = E.test_grouping_data.left_group;
right_group = E.test_grouping_data.right_group;
global_pair_rows = E.test_grouping_data.pair_rows;
probability = E.hard_negative_probability(global_pair_rows);

probability_matrix = zeros(num_starting_groups, num_starting_groups, "single");
matrix_rows = sub2ind(size(probability_matrix), left_group, right_group);
probability_matrix(matrix_rows) = single(probability);
probability_matrix = probability_matrix + probability_matrix.';
probability_matrix(1:num_starting_groups + 1:end) = 1;

candidate_rows = find(probability >= probability_cutoff);
[~, candidate_order] = sort(probability(candidate_rows), "descend");
candidate_rows = candidate_rows(candidate_order);

component_for_group = (1:num_starting_groups).';
component_members = num2cell((1:num_starting_groups).');
component_is_alive = true(num_starting_groups, 1);

merge_step = [];
pair_row = [];
pair_left_group = [];
pair_right_group = [];
pair_left_unit = [];
pair_right_unit = [];
merge_probability = [];
cross_support = [];
joined_starting_groups = {};

for candidate_id = 1:numel(candidate_rows)
    row = candidate_rows(candidate_id);
    left_component = component_for_group(left_group(row));
    right_component = component_for_group(right_group(row));

    if left_component == right_component
        continue
    end

    left_members = component_members{left_component};
    right_members = component_members{right_component};
    support_here = mean(probability_matrix(left_members, right_members) >= ...
        probability_cutoff, "all");

    if support_here >= support_cutoff
        merge_step(end + 1, 1) = numel(merge_step) + 1; %#ok<SAGROW>
        pair_row(end + 1, 1) = global_pair_rows(row); %#ok<SAGROW>
        pair_left_group(end + 1, 1) = left_group(row); %#ok<SAGROW>
        pair_right_group(end + 1, 1) = right_group(row); %#ok<SAGROW>
        pair_left_unit(end + 1, 1) = starting_group_unit(left_group(row)); %#ok<SAGROW>
        pair_right_unit(end + 1, 1) = starting_group_unit(right_group(row)); %#ok<SAGROW>
        merge_probability(end + 1, 1) = probability(row); %#ok<SAGROW>
        cross_support(end + 1, 1) = support_here; %#ok<SAGROW>
        joined_starting_groups{end + 1, 1} = ...
            [left_members(:); right_members(:)]; %#ok<SAGROW>

        component_members{left_component} = [left_members(:); right_members(:)];
        component_members{right_component} = [];
        component_for_group(right_members) = left_component;
        component_is_alive(right_component) = false;
    end
end

alive_components = find(component_is_alive);
final_group_for_starting_group = zeros(num_starting_groups, 1);
replayed_groups = cell(numel(alive_components), 1);

for group_id = 1:numel(alive_components)
    local_group_ids = component_members{alive_components(group_id)};
    final_group_for_starting_group(local_group_ids) = group_id;
    members = [];
    for member_id = 1:numel(local_group_ids)
        members = [members; starting_groups{local_group_ids(member_id)}(:)]; %#ok<AGROW>
    end
    replayed_groups{group_id} = unique(members);
end

replay_matches_saved_result = numel(replayed_groups) == numel(final_groups);
if replay_matches_saved_result
    for group_id = 1:numel(final_groups)
        replay_matches_saved_result = replay_matches_saved_result && ...
            isequal(replayed_groups{group_id}(:), final_groups{group_id}(:));
    end
end

if ~replay_matches_saved_result
    error("The grouping replay did not reproduce the saved final groups.");
end

accepted_final_group = zeros(numel(merge_step), 1);
for merge_id = 1:numel(merge_step)
    accepted_final_group(merge_id) = ...
        final_group_for_starting_group(joined_starting_groups{merge_id}(1));
end

accepted_merge_log = table(merge_step, accepted_final_group, pair_row, ...
    pair_left_group, pair_right_group, pair_left_unit, pair_right_unit, ...
    merge_probability, cross_support, ...
    T.smaller_overlap_percent(pair_row), ...
    T.reciprocal_overlap_percent(pair_row), T.matched_timestamps(pair_row), ...
    W.waveform_distance(pair_row), joined_starting_groups, ...
    'VariableNames', ["merge_step", "final_group_id", "all_pair_row", ...
    "left_starting_group", "right_starting_group", "left_unit", ...
    "right_unit", "merge_probability", "support_when_accepted", ...
    "small_timestamp_overlap", "large_timestamp_overlap", ...
    "matched_timestamps", "waveform_distance", "joined_starting_groups"]);

cross_unit_links = accepted_merge_log( ...
    accepted_merge_log.left_unit ~= accepted_merge_log.right_unit & ...
    ismember(accepted_merge_log.final_group_id, bad_group_ids), :);

fprintf("Grouping replay matched the saved result.\n");
fprintf("Accepted cross-unit links inside contaminated groups: %d\n", ...
    height(cross_unit_links));
disp(cross_unit_links(:, ["merge_step", "final_group_id", ...
    "left_starting_group", "right_starting_group", "left_unit", ...
    "right_unit", "merge_probability", "support_when_accepted", ...
    "small_timestamp_overlap", "large_timestamp_overlap", ...
    "matched_timestamps", "waveform_distance"]));

%% Make one simple group-by-unit map

[~, display_order] = sort(final_group_summary.dominant_unit);
display_matrix = group_unit_matrix(display_order, :);

figure("Color", "w", "Name", "Held-out final group by unit map");
imagesc(display_matrix);
color_bar = colorbar;
xlabel("Held-out unit");
ylabel("Final groups, sorted by dominant unit");
title(sprintf("Final held-out groups: %d groups / %d units = %.3f", ...
    num_final_groups, num_unique_units, groups_per_unit_ratio), "Color", "k");
colormap(parula);
axes_here = gca;
axes_here.XColor = "k";
axes_here.YColor = "k";
color_bar.Color = "k";

tick_positions = 1:5:num_unique_units;
xticks(tick_positions);
xticklabels(string(test_units(tick_positions)));

hold on
for bad_id = 1:numel(bad_group_ids)
    row = find(display_order == bad_group_ids(bad_id), 1);
    columns = find(display_matrix(row, :) > 0);
    plot(columns, repmat(row, size(columns)), "rs", ...
        "MarkerSize", 9, "LineWidth", 1.5);
end
hold off
exportgraphics(gcf, figure_file, "Resolution", 200);

%% Save the audit

if isfile(save_file)
    delete(save_file);
end

save(save_file, "overall_summary", "bad_group_summary", ...
    "bad_cluster_details", "accepted_merge_log", "cross_unit_links", ...
    "group_unit_matrix", "test_units", "replay_matches_saved_result", ...
    "probability_cutoff", "support_cutoff", "-v7.3");

fprintf("\nSaved analysis to:\n%s\n", save_file);
fprintf("Saved group-unit map to:\n%s\n", figure_file);
fprintf("total time %.1f seconds\n", toc(total_tic));

% This is a post-hoc test-set audit. It is fine for understanding failures,
% but the same 69 test units should not be reused to choose a new model or
% cutoff and then reported again as an untouched final test.
