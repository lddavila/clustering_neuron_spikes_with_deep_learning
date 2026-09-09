%% Recording 6: run the trained group-pair NN and regroup
%
% This script uses the neural network that was trained with recording 10.
% It does not train or change the network. It scores every pair of recording 6
% remove_conflicts groups, then applies the same safe grouping rule used in
% run_group_pair_nn_clear_experiment.m.
%
% Max_Overlap_Unit is not used by the neural network or by the grouping rule.
% It is used only at the end to check the result on this simulated recording.

clearvars
clc

total_tic = tic;

SCORING_BATCH_SIZE = 200000;

script_folder = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(script_folder)));

addpath(genpath(fullfile(repo_root, "clustering-master")));
addpath(genpath(fullfile(repo_root, "Utility_Functions")));
addpath(genpath(fullfile(repo_root, "Neural_Networks")));
cd(repo_root);

result_folder = fullfile(repo_root, "Default_Results_Dir", ...
    "recording_6_new_pipeline");
dataset_file = fullfile(result_folder, ...
    "recording_6_complete_nn_test_features.mat");
starting_group_file = fullfile(result_folder, ...
    "recording_6_min170_accuracy15_remove_conflicts.mat");
model_file = fullfile(repo_root, "Default_Results_Dir", ...
    "group_pair_nn_clear_experiment_result.mat");
probability_file = fullfile(result_folder, ...
    "recording_6_nn_pair_probabilities.mat");
save_file = fullfile(result_folder, ...
    "recording_6_nn_regrouping_result.mat");

if ~isfile(dataset_file)
    error("Run step_4_build_nn_test_features.m first.");
end

if ~isfile(starting_group_file)
    error("The recording 6 remove_conflicts result was not found.");
end

if ~isfile(model_file)
    error("The saved nine-feature neural network was not found.");
end

%% Load the trained network and check the test dataset

fprintf("\nLoading the trained network and recording 6 information...\n");
load_tic = tic;

model_result = load(model_file, "final_net", "final_feature_mean", ...
    "final_feature_std", "feature_names", ...
    "selected_probability_cutoff", "selected_support_cutoff");

required_model_fields = [
    "final_net"
    "final_feature_mean"
    "final_feature_std"
    "feature_names"
    "selected_probability_cutoff"
    "selected_support_cutoff"
];

for field_number = 1:numel(required_model_fields)
    if ~isfield(model_result, required_model_fields(field_number))
        error("The saved model is missing %s.", required_model_fields(field_number));
    end
end

dataset_info = load(dataset_file, "dataset_complete", "number_of_groups", ...
    "number_of_pairs", "number_of_features", "feature_names", ...
    "feature_mean", "feature_std", "source_group_file");

if ~dataset_info.dataset_complete
    error("The recording 6 feature dataset is not complete.");
end

model_feature_names = string(model_result.feature_names(:));
dataset_feature_names = string(dataset_info.feature_names(:));

if ~isequal(model_feature_names, dataset_feature_names)
    error("The recording 6 feature order does not match the trained network.");
end

mean_matches = max(abs(double(dataset_info.feature_mean(:)) - ...
    double(model_result.final_feature_mean(:)))) < 1e-10;
std_matches = max(abs(double(dataset_info.feature_std(:)) - ...
    double(model_result.final_feature_std(:)))) < 1e-10;

if ~mean_matches || ~std_matches
    error("The recording 6 features were normalized with different values.");
end

group_result = load(starting_group_file, "remove_conflicts_groups", ...
    "group_summary", "grouping_summary", "kept_row_indices", "input_file");

starting_groups = group_result.remove_conflicts_groups;
number_of_starting_groups = numel(starting_groups);
number_of_pairs = double(dataset_info.number_of_pairs);
number_of_features = double(dataset_info.number_of_features);

if number_of_starting_groups ~= dataset_info.number_of_groups
    error("The feature dataset and starting groups do not match.");
end

if string(dataset_info.source_group_file) ~= string(starting_group_file)
    error("The feature dataset was made from a different group file.");
end

probability_cutoff = double(model_result.selected_probability_cutoff);
support_cutoff = double(model_result.selected_support_cutoff);
final_net = model_result.final_net;
feature_names = dataset_feature_names;

fprintf("starting remove_conflicts groups: %d\n", number_of_starting_groups);
fprintf("group pairs to score:             %d\n", number_of_pairs);
fprintf("features per pair:                %d\n", number_of_features);
fprintf("merge probability cutoff:         %.4f\n", probability_cutoff);
fprintf("cross-group support cutoff:       %.2f\n", support_cutoff);
fprintf("loading took %.1f seconds\n", toc(load_tic));

clear model_result dataset_info

%% Score every recording 6 group pair

% The saved feature file is read in batches so the complete 29-million-row
% feature matrix does not have to be copied into memory at once.
dataset = matfile(dataset_file);

if isfile(probability_file)
    probability_info = load(probability_file, "source_dataset_file", ...
        "source_model_file", "number_of_pairs", "number_of_features", ...
        "last_scored_pair", "scoring_complete");

    probability_file_matches = ...
        string(probability_info.source_dataset_file) == string(dataset_file) && ...
        string(probability_info.source_model_file) == string(model_file) && ...
        probability_info.number_of_pairs == number_of_pairs && ...
        probability_info.number_of_features == number_of_features;

    if ~probability_file_matches
        error("The existing probability file belongs to a different experiment.");
    end

    last_scored_pair = double(probability_info.last_scored_pair);
    scoring_complete = probability_info.scoring_complete;
else
    fprintf("\nCreating the neural-network probability file...\n");

    source_dataset_file = dataset_file;
    source_model_file = model_file;
    last_scored_pair = uint64(0);
    scoring_complete = false;

    save(probability_file, "source_dataset_file", "source_model_file", ...
        "number_of_pairs", "number_of_features", "feature_names", ...
        "probability_cutoff", "support_cutoff", "last_scored_pair", ...
        "scoring_complete", "-v7.3");

    probability_data = matfile(probability_file, "Writable", true);
    probability_data.merge_probability(number_of_pairs, 1) = single(0);
end

probability_data = matfile(probability_file, "Writable", true);

if scoring_complete
    fprintf("\nAll pair probabilities were already scored.\n");
else
    first_pair_this_run = last_scored_pair + 1;
    number_of_batches = ceil((number_of_pairs - last_scored_pair) / ...
        SCORING_BATCH_SIZE);

    fprintf("\nScoring all group pairs with the trained network...\n");
    fprintf("resuming at pair %d / %d\n", first_pair_this_run, number_of_pairs);
    score_tic = tic;
    batch_number = 0;

    for batch_start = first_pair_this_run:SCORING_BATCH_SIZE:number_of_pairs
        batch_number = batch_number + 1;
        batch_end = min(batch_start + SCORING_BATCH_SIZE - 1, number_of_pairs);
        batch_rows = batch_start:batch_end;

        normalized_features = dataset.normalized_features(batch_rows, :);
        scores = predict(final_net, normalized_features);
        merge_probability = single(scores(:, 2));

        probability_data.merge_probability(batch_rows, 1) = merge_probability;
        probability_data.last_scored_pair = uint64(batch_end);

        processed_this_run = batch_end - first_pair_this_run + 1;
        elapsed = toc(score_tic);
        rows_per_second = processed_this_run / max(elapsed, eps);
        seconds_remaining = ...
            (number_of_pairs - batch_end) / max(rows_per_second, eps);

        fprintf("scored batch %d / %d | pairs %d / %d (%.1f%%) | " + ...
            "time %.1f min | estimated remaining %.1f min\n", ...
            batch_number, number_of_batches, batch_end, number_of_pairs, ...
            100 * batch_end / number_of_pairs, elapsed / 60, ...
            seconds_remaining / 60);
    end

    probability_data.scoring_complete = true;
    probability_data.scoring_seconds = toc(score_tic);
    fprintf("neural-network scoring took %.1f minutes\n", toc(score_tic) / 60);
end

clear final_net normalized_features scores merge_probability

%% Load the probabilities and create the pair-probability matrix

fprintf("\nPreparing the safe grouping rule...\n");
grouping_tic = tic;

merge_probability = probability_data.merge_probability;
pair_group_a = dataset.group_a;
pair_group_b = dataset.group_b;

candidate_rows = find(merge_probability >= probability_cutoff);
[~, candidate_order] = sort(merge_probability(candidate_rows), "descend");
candidate_rows = candidate_rows(candidate_order);

fprintf("candidate links at probability %.4f: %d\n", ...
    probability_cutoff, numel(candidate_rows));

% This matrix stores the neural-network probability for each pair of
% starting groups. It is not the earlier cluster merge matrix.
probability_matrix = zeros(number_of_starting_groups, ...
    number_of_starting_groups, "single");

for batch_start = 1:SCORING_BATCH_SIZE:number_of_pairs
    batch_end = min(batch_start + SCORING_BATCH_SIZE - 1, number_of_pairs);
    batch_rows = batch_start:batch_end;
    group_a_here = double(pair_group_a(batch_rows));
    group_b_here = double(pair_group_b(batch_rows));
    matrix_rows = group_a_here + ...
        (group_b_here - 1) * number_of_starting_groups;
    probability_matrix(matrix_rows) = merge_probability(batch_rows);
end

probability_matrix = probability_matrix + probability_matrix.';
probability_matrix(1:number_of_starting_groups + 1:end) = 1;

fprintf("probability matrix prepared in %.1f seconds\n", toc(grouping_tic));

%% Apply the same safe grouping policy used in the original experiment

fprintf("\nRegrouping from highest probability to lowest...\n");
safe_grouping_tic = tic;

component_for_group = (1:number_of_starting_groups).';
component_members = num2cell((1:number_of_starting_groups).');
component_is_alive = true(number_of_starting_groups, 1);
safe_merges = 0;

for candidate_number = 1:numel(candidate_rows)
    pair_row = candidate_rows(candidate_number);
    left_group = double(pair_group_a(pair_row));
    right_group = double(pair_group_b(pair_row));
    left_component = component_for_group(left_group);
    right_component = component_for_group(right_group);

    if left_component ~= right_component
        left_members = component_members{left_component};
        right_members = component_members{right_component};
        cross_probabilities = probability_matrix(left_members, right_members);
        cross_support = mean(cross_probabilities(:) >= probability_cutoff);

        if cross_support >= support_cutoff
            component_members{left_component} = [left_members(:); right_members(:)];
            component_members{right_component} = [];
            component_for_group(right_members) = left_component;
            component_is_alive(right_component) = false;
            safe_merges = safe_merges + 1;
        end
    end

    if mod(candidate_number, 10000) == 0 || ...
            candidate_number == numel(candidate_rows)
        fprintf("checked %d / %d candidate links (%.1f%%) | " + ...
            "accepted merges %d | time %.1f sec\n", ...
            candidate_number, numel(candidate_rows), ...
            100 * candidate_number / max(numel(candidate_rows), 1), ...
            safe_merges, toc(safe_grouping_tic));
    end
end

alive_components = find(component_is_alive);
nn_groups = cell(numel(alive_components), 1);

for final_group_id = 1:numel(alive_components)
    starting_group_ids = component_members{alive_components(final_group_id)};
    cluster_members = [];

    for member_number = 1:numel(starting_group_ids)
        cluster_members = [cluster_members; ...
            starting_groups{starting_group_ids(member_number)}(:)]; %#ok<AGROW>
    end

    nn_groups{final_group_id} = unique(cluster_members);
end

number_of_final_groups = numel(nn_groups);
number_of_clusters = sum(cellfun(@numel, nn_groups));
all_group_members = sort(vertcat(nn_groups{:}));

if ~isequal(all_group_members, (1:number_of_clusters).')
    error("Some filtered clusters are missing or appear in more than one NN group.");
end

fprintf("safe merges accepted:           %d\n", safe_merges);
fprintf("final NN groups:                %d\n", number_of_final_groups);
fprintf("safe grouping took %.1f seconds\n", toc(safe_grouping_tic));

clear probability_matrix component_for_group component_members
clear component_is_alive pair_group_a pair_group_b candidate_order

%% Evaluate the final groups with simulated ground truth

% Nothing below this point changes the groups. Max_Overlap_Unit is loaded
% only now, after all neural-network decisions have already been made.
fprintf("\nChecking the final groups with Max_Overlap_Unit...\n");
evaluation_tic = tic;

input_result = load(group_result.input_file, "data_to_save");
bp_filtered = input_result.data_to_save(group_result.kept_row_indices, :);

if ~ismember("Max_Overlap_Unit", string(bp_filtered.Properties.VariableNames))
    error("Max_Overlap_Unit is required only for this final evaluation.");
end

max_overlap_unit = bp_filtered{:, "Max_Overlap_Unit"};
retained_units = unique(max_overlap_unit);
number_of_retained_units = numel(retained_units);

group_id = (1:number_of_final_groups).';
group_size = zeros(number_of_final_groups, 1);
num_units = zeros(number_of_final_groups, 1);
dominant_unit = nan(number_of_final_groups, 1);
dominant_cluster_count = zeros(number_of_final_groups, 1);
purity = zeros(number_of_final_groups, 1);
is_pure = false(number_of_final_groups, 1);
contaminating_cluster_count = zeros(number_of_final_groups, 1);
unit_list = cell(number_of_final_groups, 1);
cluster_group_id = zeros(number_of_clusters, 1);

for current_group = 1:number_of_final_groups
    members = nn_groups{current_group};
    units_here = max_overlap_unit(members);
    unique_units_here = unique(units_here);
    unit_counts = zeros(numel(unique_units_here), 1);

    for unit_number = 1:numel(unique_units_here)
        unit_counts(unit_number) = sum(units_here == unique_units_here(unit_number));
    end

    [largest_count, largest_position] = max(unit_counts);
    group_size(current_group) = numel(members);
    num_units(current_group) = numel(unique_units_here);
    dominant_unit(current_group) = unique_units_here(largest_position);
    dominant_cluster_count(current_group) = largest_count;
    purity(current_group) = largest_count / numel(members);
    is_pure(current_group) = isscalar(unique_units_here);
    contaminating_cluster_count(current_group) = ...
        numel(members) - largest_count;
    unit_list{current_group} = unique_units_here(:).';
    cluster_group_id(members) = current_group;
end

nn_group_summary = table(group_id, group_size, num_units, dominant_unit, ...
    dominant_cluster_count, purity, is_pure, contaminating_cluster_count, ...
    unit_list);

unit_id = retained_units(:);
groups_with_unit = zeros(number_of_retained_units, 1);
clean_group_count = zeros(number_of_retained_units, 1);
perfectly_contained = false(number_of_retained_units, 1);
clusters_for_unit = zeros(number_of_retained_units, 1);

for unit_number = 1:number_of_retained_units
    this_unit = unit_id(unit_number);
    cluster_rows = find(max_overlap_unit == this_unit);
    groups_for_this_unit = unique(cluster_group_id(cluster_rows));

    groups_with_unit(unit_number) = numel(groups_for_this_unit);
    clean_group_count(unit_number) = sum(is_pure(groups_for_this_unit));
    perfectly_contained(unit_number) = ...
        isscalar(groups_for_this_unit) && is_pure(groups_for_this_unit);
    clusters_for_unit(unit_number) = numel(cluster_rows);
end

nn_unit_summary = table(unit_id, groups_with_unit, clean_group_count, ...
    perfectly_contained, clusters_for_unit);

pure_groups = sum(is_pure);
contaminated_groups = sum(~is_pure);
clusters_in_pure_groups = sum(group_size(is_pure));
groups_per_retained_unit = number_of_final_groups / number_of_retained_units;
fully_pure_group_percent = 100 * pure_groups / number_of_final_groups;
mean_group_purity_percent = 100 * mean(purity);
clusters_in_pure_percent = 100 * clusters_in_pure_groups / number_of_clusters;
fragmented_unit_count = sum(groups_with_unit > 1);
perfectly_contained_unit_count = sum(perfectly_contained);
units_with_clean_group = sum(clean_group_count > 0);

nn_grouping_summary = table("recording_6_nn", probability_cutoff, ...
    support_cutoff, numel(candidate_rows), safe_merges, ...
    number_of_final_groups, number_of_clusters, number_of_retained_units, ...
    groups_per_retained_unit, pure_groups, fully_pure_group_percent, ...
    mean_group_purity_percent, clusters_in_pure_groups, ...
    clusters_in_pure_percent, contaminated_groups, max(group_size), ...
    fragmented_unit_count, perfectly_contained_unit_count, ...
    units_with_clean_group, ...
    'VariableNames', {'method_name', 'probability_cutoff', ...
    'support_cutoff', 'candidate_links', 'safe_merges', 'num_groups', ...
    'num_clusters', 'num_unique_units', 'groups_per_unit_ratio', ...
    'pure_groups', 'fully_pure_group_percent', ...
    'mean_group_purity_percent', 'clusters_in_pure_groups', ...
    'clusters_in_pure_percent', 'contaminated_groups', ...
    'largest_group_size', 'fragmented_units', ...
    'perfectly_contained_units', 'units_with_clean_group'});

fprintf("evaluation took %.1f seconds\n", toc(evaluation_tic));

%% Print the result and the starting reference

fprintf("\n--- Recording 6 NN Regrouping Summary ---\n");
fprintf("trained model source:                recording 10 experiment\n");
fprintf("probability cutoff:                  %.4f\n", probability_cutoff);
fprintf("support cutoff:                      %.2f\n", support_cutoff);
fprintf("candidate pair links:                %d\n", numel(candidate_rows));
fprintf("safe merges accepted:                %d\n", safe_merges);
fprintf("groups:                              %d\n", number_of_final_groups);
fprintf("clusters:                            %d\n", number_of_clusters);
fprintf("retained unique units:               %d\n", number_of_retained_units);
fprintf("groups / retained units:             %.3f\n", groups_per_retained_unit);
fprintf("pure groups:                         %d (%.2f%%)\n", ...
    pure_groups, fully_pure_group_percent);
fprintf("contaminated groups:                 %d\n", contaminated_groups);
fprintf("mean group purity:                   %.2f%%\n", ...
    mean_group_purity_percent);
fprintf("clusters in completely pure groups: %d (%.2f%%)\n", ...
    clusters_in_pure_groups, clusters_in_pure_percent);
fprintf("largest group size:                  %d\n", max(group_size));
fprintf("fragmented units:                    %d (%.2f%%)\n", ...
    fragmented_unit_count, ...
    100 * fragmented_unit_count / number_of_retained_units);
fprintf("perfectly contained units:           %d (%.2f%%)\n", ...
    perfectly_contained_unit_count, ...
    100 * perfectly_contained_unit_count / number_of_retained_units);
fprintf("units with at least one clean group: %d (%.2f%%)\n", ...
    units_with_clean_group, ...
    100 * units_with_clean_group / number_of_retained_units);

bad_groups = nn_group_summary(~nn_group_summary.is_pure, :);
bad_groups = sortrows(bad_groups, ...
    ["contaminating_cluster_count", "group_size"], "descend");
largest_groups = sortrows(nn_group_summary, "group_size", "descend");
fragmented_units = nn_unit_summary(nn_unit_summary.groups_with_unit > 1, :);
fragmented_units = sortrows(fragmented_units, "groups_with_unit", "descend");

fprintf("\nLargest contaminated groups\n");
if isempty(bad_groups)
    fprintf("none\n");
else
    disp(bad_groups(1:min(15, height(bad_groups)), :));
end

fprintf("\nLargest groups\n");
disp(largest_groups(1:min(15, height(largest_groups)), :));

fprintf("\nMost fragmented units\n");
if isempty(fragmented_units)
    fprintf("none\n");
else
    disp(fragmented_units(1:min(15, height(fragmented_units)), :));
end

starting_summary = group_result.grouping_summary;
starting_groups_per_unit = starting_summary.groups_per_retained_unit;
starting_fully_pure = starting_summary.fully_pure_group_percent;
starting_mean_purity = starting_summary.mean_group_purity_percent;
starting_clusters_pure = starting_summary.clusters_in_pure_percent;
starting_bad = starting_summary.contaminated_groups;

comparison = table(["remove_conflicts"; "recording_6_nn"], ...
    [height(group_result.group_summary); number_of_final_groups], ...
    [starting_groups_per_unit; groups_per_retained_unit], ...
    [starting_fully_pure; fully_pure_group_percent], ...
    [starting_mean_purity; mean_group_purity_percent], ...
    [starting_clusters_pure; clusters_in_pure_percent], ...
    [starting_bad; contaminated_groups], ...
    'VariableNames', {'method_name', 'num_groups', ...
    'groups_per_unit_ratio', 'fully_pure_group_percent', ...
    'mean_group_purity_percent', 'clusters_in_pure_percent', ...
    'contaminated_groups'});

fprintf("\nRemove conflicts and NN comparison\n");
disp(comparison);

%% Save the regrouped result

total_seconds = toc(total_tic);
source_dataset_file = dataset_file;
source_model_file = model_file;
source_starting_group_file = starting_group_file;

save(save_file, "nn_groups", "nn_group_summary", "nn_unit_summary", ...
    "nn_grouping_summary", "comparison", "bad_groups", ...
    "largest_groups", "fragmented_units", "probability_cutoff", ...
    "support_cutoff", "feature_names", "candidate_rows", "safe_merges", ...
    "source_dataset_file", "source_model_file", ...
    "source_starting_group_file", "probability_file", "total_seconds", ...
    "group_result", "-v7.3");

fprintf("\nPair probabilities were saved to:\n%s\n", probability_file);
fprintf("\nFinal regrouping result was saved to:\n%s\n", save_file);
fprintf("total script time: %.1f minutes\n", total_seconds / 60);

%
