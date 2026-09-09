%% Recording 6: make remove_conflicts groups and evaluate them
%
% Run this after step_2_build_cluster_merge_matrix.m finishes. This script does
% not run the five neural networks again. It only uses their saved matrix.

clearvars
clc

total_tic = tic;

script_folder = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(script_folder)));
result_folder = fullfile(repo_root, "Default_Results_Dir", ...
    "recording_6_new_pipeline");

matrix_file = fullfile(result_folder, ...
    "recording_6_min170_accuracy15_merge_matrix.mat");
checkpoint_file = fullfile(result_folder, ...
    "recording_6_min170_accuracy15_matrix_checkpoint.mat");
save_file = fullfile(result_folder, ...
    "recording_6_min170_accuracy15_remove_conflicts.mat");

if ~isfile(matrix_file)
    if isfile(checkpoint_file)
        error("The matrix is not finished yet. Its checkpoint file still exists.");
    end
    error("The completed recording 6 matrix file was not found.");
end

%% Load the matrix and the same filtered clusters

fprintf("\nLoading the completed recording 6 matrix...\n");
load_tic = tic;

matrix_result = load(matrix_file, "merge_matrix", "kept_row_indices", ...
    "input_file", "filter_summary", "filter_method");

required_fields = ["merge_matrix", "kept_row_indices", "input_file"];
for field_number = 1:numel(required_fields)
    if ~isfield(matrix_result, required_fields(field_number))
        error("The matrix result is missing %s.", required_fields(field_number));
    end
end

input_data = load(matrix_result.input_file, "data_to_save");
if ~isfield(input_data, "data_to_save") || ~istable(input_data.data_to_save)
    error("The original blind-pass table could not be loaded.");
end

bp = input_data.data_to_save;
kept_row_indices = matrix_result.kept_row_indices;
bp_filtered = bp(kept_row_indices, :);
merge_matrix = logical(matrix_result.merge_matrix);

number_of_clusters = height(bp_filtered);
if size(merge_matrix, 1) ~= number_of_clusters || ...
        size(merge_matrix, 2) ~= number_of_clusters
    error("The matrix size does not match the filtered blind-pass table.");
end

if ~isequal(merge_matrix, merge_matrix.')
    error("The saved merge matrix is not symmetric.");
end

if ~all(diag(merge_matrix))
    error("The merge matrix diagonal is incomplete.");
end

if ~ismember("Max_Overlap_Unit", string(bp_filtered.Properties.VariableNames))
    error("Max_Overlap_Unit is required for the evaluation summary.");
end

max_overlap_unit = bp_filtered{:, "Max_Overlap_Unit"};
retained_units = unique(max_overlap_unit);
number_of_retained_units = numel(retained_units);

if ismember("Max_Overlap_Unit", string(bp.Properties.VariableNames))
    number_of_original_units = numel(unique(bp{:, "Max_Overlap_Unit"}));
else
    number_of_original_units = NaN;
end

number_of_merge_links = nnz(triu(merge_matrix, 1));

fprintf("matrix size:                   %d x %d\n", ...
    number_of_clusters, number_of_clusters);
fprintf("accepted merge links:          %d\n", number_of_merge_links);
fprintf("retained unique units:         %d\n", number_of_retained_units);
fprintf("original unique units:         %d\n", number_of_original_units);
fprintf("loading took %.1f seconds\n", toc(load_tic));

clear bp input_data

%% Find clusters that create conflicting links

fprintf("\nFinding conflict clusters...\n");
conflict_tic = tic;

links = merge_matrix;
links(1:number_of_clusters + 1:end) = false;
is_conflict_cluster = false(number_of_clusters, 1);

for cluster_id = 1:number_of_clusters
    linked_clusters = find(links(cluster_id, :));

    if numel(linked_clusters) >= 2
        links_between_neighbors = links(linked_clusters, linked_clusters);
        links_between_neighbors(1:numel(linked_clusters) + 1:end) = true;

        % If two neighbors do not link to each other, this cluster is the
        % conflict. It will be kept, but it will become a singleton group.
        if ~all(links_between_neighbors, "all")
            is_conflict_cluster(cluster_id) = true;
        end
    end

    if mod(cluster_id, 500) == 0 || cluster_id == number_of_clusters
        fprintf("checked %d / %d clusters (%.1f%%), time %.1f sec\n", ...
            cluster_id, number_of_clusters, ...
            100 * cluster_id / number_of_clusters, toc(conflict_tic));
    end
end

conflict_clusters = find(is_conflict_cluster);
clean_clusters = find(~is_conflict_cluster);

fprintf("conflict clusters found:       %d\n", numel(conflict_clusters));
fprintf("conflict check took %.1f seconds\n", toc(conflict_tic));

%% Make groups from the matrix after removing conflicts

fprintf("\nMaking remove_conflicts groups...\n");
group_tic = tic;

clean_links = links(clean_clusters, clean_clusters);
clean_graph = graph(clean_links);
component_number = conncomp(clean_graph);
number_of_clean_groups = max(component_number);

remove_conflicts_groups = cell( ...
    number_of_clean_groups + numel(conflict_clusters), 1);

for group_id = 1:number_of_clean_groups
    members_in_clean_list = component_number == group_id;
    remove_conflicts_groups{group_id} = ...
        clean_clusters(members_in_clean_list);
end

for conflict_id = 1:numel(conflict_clusters)
    group_id = number_of_clean_groups + conflict_id;
    remove_conflicts_groups{group_id} = conflict_clusters(conflict_id);
end

all_group_members = sort(vertcat(remove_conflicts_groups{:}));
if ~isequal(all_group_members, (1:number_of_clusters).')
    error("Some clusters are missing from the groups or appear more than once.");
end

number_of_groups = numel(remove_conflicts_groups);
fprintf("groups made:                   %d\n", number_of_groups);
fprintf("grouping took %.1f seconds\n", toc(group_tic));

%% Summarize each group

fprintf("\nSummarizing groups...\n");
summary_tic = tic;

group_id = (1:number_of_groups).';
group_size = zeros(number_of_groups, 1);
num_units = zeros(number_of_groups, 1);
dominant_unit = nan(number_of_groups, 1);
dominant_cluster_count = zeros(number_of_groups, 1);
purity = zeros(number_of_groups, 1);
is_pure = false(number_of_groups, 1);
contaminating_cluster_count = zeros(number_of_groups, 1);
unit_list = cell(number_of_groups, 1);
cluster_group_id = zeros(number_of_clusters, 1);

for current_group = 1:number_of_groups
    members = remove_conflicts_groups{current_group};
    units_here = max_overlap_unit(members);
    units_here_unique = unique(units_here);
    unit_counts = zeros(numel(units_here_unique), 1);

    for unit_number = 1:numel(units_here_unique)
        unit_counts(unit_number) = sum(units_here == units_here_unique(unit_number));
    end

    [largest_unit_count, largest_unit_position] = max(unit_counts);

    group_size(current_group) = numel(members);
    num_units(current_group) = numel(units_here_unique);
    dominant_unit(current_group) = units_here_unique(largest_unit_position);
    dominant_cluster_count(current_group) = largest_unit_count;
    purity(current_group) = largest_unit_count / numel(members);
    is_pure(current_group) = isscalar(units_here_unique);
    contaminating_cluster_count(current_group) = ...
        numel(members) - largest_unit_count;
    unit_list{current_group} = units_here_unique(:).';
    cluster_group_id(members) = current_group;
end

group_summary = table(group_id, group_size, num_units, dominant_unit, ...
    dominant_cluster_count, purity, is_pure, contaminating_cluster_count, ...
    unit_list);

%% Summarize each retained unit

unit_id = retained_units(:);
groups_with_unit = zeros(number_of_retained_units, 1);
clean_group_count = zeros(number_of_retained_units, 1);
perfectly_contained = false(number_of_retained_units, 1);
clusters_for_unit = zeros(number_of_retained_units, 1);

for unit_number = 1:number_of_retained_units
    this_unit = unit_id(unit_number);
    cluster_rows = find(max_overlap_unit == this_unit);
    group_rows = unique(cluster_group_id(cluster_rows));

    groups_with_unit(unit_number) = numel(group_rows);
    clean_group_count(unit_number) = sum(is_pure(group_rows));
    perfectly_contained(unit_number) = ...
        isscalar(group_rows) && is_pure(group_rows);
    clusters_for_unit(unit_number) = numel(cluster_rows);
end

unit_summary = table(unit_id, groups_with_unit, clean_group_count, ...
    perfectly_contained, clusters_for_unit);

fprintf("summaries took %.1f seconds\n", toc(summary_tic));

%% Print the main results

pure_groups = sum(group_summary.is_pure);
contaminated_groups = sum(~group_summary.is_pure);
clusters_in_pure_groups = sum( ...
    group_summary.group_size(group_summary.is_pure));

fully_pure_group_percent = 100 * pure_groups / number_of_groups;
mean_group_purity_percent = 100 * mean(group_summary.purity);
clusters_in_pure_percent = ...
    100 * clusters_in_pure_groups / number_of_clusters;
groups_per_retained_unit = number_of_groups / number_of_retained_units;
retained_unit_percent = ...
    100 * number_of_retained_units / number_of_original_units;

fragmented_unit_count = sum(unit_summary.groups_with_unit > 1);
perfectly_contained_unit_count = sum(unit_summary.perfectly_contained);
units_with_clean_group = sum(unit_summary.clean_group_count > 0);

fprintf("\n--- Recording 6 Remove Conflicts Summary ---\n");
fprintf("groups:                              %d\n", number_of_groups);
fprintf("clusters:                            %d\n", number_of_clusters);
fprintf("retained unique units:               %d\n", number_of_retained_units);
fprintf("original unique units:               %d\n", number_of_original_units);
fprintf("units retained after filter:         %.2f%%\n", retained_unit_percent);
fprintf("groups / retained units:             %.3f\n", groups_per_retained_unit);
fprintf("pure groups:                         %d (%.2f%%)\n", ...
    pure_groups, fully_pure_group_percent);
fprintf("contaminated groups:                 %d\n", contaminated_groups);
fprintf("mean group purity:                   %.2f%%\n", ...
    mean_group_purity_percent);
fprintf("clusters in completely pure groups: %d (%.2f%%)\n", ...
    clusters_in_pure_groups, clusters_in_pure_percent);
fprintf("largest group size:                  %d\n", ...
    max(group_summary.group_size));
fprintf("fragmented units:                    %d (%.2f%%)\n", ...
    fragmented_unit_count, ...
    100 * fragmented_unit_count / number_of_retained_units);
fprintf("perfectly contained units:           %d (%.2f%%)\n", ...
    perfectly_contained_unit_count, ...
    100 * perfectly_contained_unit_count / number_of_retained_units);
fprintf("units with at least one clean group: %d (%.2f%%)\n", ...
    units_with_clean_group, ...
    100 * units_with_clean_group / number_of_retained_units);

bad_groups = group_summary(~group_summary.is_pure, :);
bad_groups = sortrows(bad_groups, ...
    ["contaminating_cluster_count", "group_size"], "descend");
largest_groups = sortrows(group_summary, "group_size", "descend");
fragmented_units = unit_summary(unit_summary.groups_with_unit > 1, :);
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

grouping_summary = table(number_of_groups, number_of_clusters, ...
    number_of_retained_units, number_of_original_units, ...
    retained_unit_percent, groups_per_retained_unit, pure_groups, ...
    fully_pure_group_percent, contaminated_groups, ...
    mean_group_purity_percent, clusters_in_pure_groups, ...
    clusters_in_pure_percent, fragmented_unit_count, ...
    perfectly_contained_unit_count, units_with_clean_group);

total_seconds = toc(total_tic);
input_file = matrix_result.input_file;

save(save_file, "remove_conflicts_groups", "conflict_clusters", ...
    "clean_clusters", "group_summary", "unit_summary", ...
    "grouping_summary", "bad_groups", "largest_groups", ...
    "fragmented_units", "kept_row_indices", "input_file", ...
    "matrix_file", "number_of_merge_links", "total_seconds", "-v7.3");

fprintf("\nsaved result to:\n%s\n", save_file);
fprintf("total script time: %.1f seconds\n", total_seconds);
