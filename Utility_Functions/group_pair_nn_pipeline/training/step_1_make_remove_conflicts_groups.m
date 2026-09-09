%%
% Remove-conflicts grouping from the saved merge matrix.
%
% This script does not rebuild the matrix. It only loads the matrix we already
% made, removes the conflict clusters, makes groups from the clean part, and
% prints the numbers I need to explain what happened.

clear
clc

total_tic = tic;

script_folder = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(script_folder)));
addpath(genpath(repo_root), "-begin");

matrix_file = fullfile(repo_root, "Default_Results_Dir", "merge_matrix_5000ish.mat");
table_file = fullfile(repo_root, "Default_Results_Dir", "readable_matrix_grouping_run.mat");
save_file = fullfile(repo_root, "Default_Results_Dir", "remove_conflicts_only_result.mat");

%% load the matrix and the filtered table

fprintf("\nLoading the saved matrix and filtered table...\n");
load_tic = tic;

matrix_data = load(matrix_file);

if isfield(matrix_data, "merge_matrix")
    merge_matrix = matrix_data.merge_matrix;
elseif isfield(matrix_data, "group_matrix")
    merge_matrix = matrix_data.group_matrix;
elseif isfield(matrix_data, "A")
    merge_matrix = matrix_data.A;
else
    names = fieldnames(matrix_data);
    merge_matrix = matrix_data.(names{1});
    fprintf("Using matrix variable named %s\n", names{1});
end

table_data = load(table_file, "bp_small");
bp_filtered = table_data.bp_small;

merge_matrix = logical(merge_matrix);
num_clusters = size(merge_matrix, 1);

% Make sure the matrix is symmetric and the diagonal is true.
merge_matrix = merge_matrix | merge_matrix.';
merge_matrix(1:num_clusters + 1:end) = true;

if height(bp_filtered) ~= num_clusters
    error("The table has %d rows, but the matrix has %d rows.", height(bp_filtered), num_clusters);
end

max_overlap_unit = bp_filtered{:, "Max_Overlap_Unit"};
unique_units = unique(max_overlap_unit);
num_merge_pairs = nnz(triu(merge_matrix, 1));

fprintf("Matrix size: %d x %d\n", num_clusters, num_clusters);
fprintf("Clusters in filtered table: %d\n", height(bp_filtered));
fprintf("Unique Max_Overlap_Unit values: %d\n", numel(unique_units));
fprintf("Merge pairs in matrix: %d\n", num_merge_pairs);
fprintf("Loading took %.1f seconds\n", toc(load_tic));

%% find the conflict clusters

fprintf("\nFinding conflict clusters...\n");
conflict_tic = tic;

% For this part I only care about links between different clusters.
links = merge_matrix;
links(1:num_clusters + 1:end) = false;

is_conflict_cluster = false(num_clusters, 1);

for cluster_id = 1:num_clusters
    linked_clusters = find(links(cluster_id, :));

    % A conflict can only happen if this cluster links to at least 2 others.
    if numel(linked_clusters) >= 2
        links_between_them = links(linked_clusters, linked_clusters);
        links_between_them(1:numel(linked_clusters) + 1:end) = true;

        % If this cluster links to two clusters that do not link to each other,
        % then this cluster is causing a conflict, so I pull it out.
        if ~all(links_between_them(:))
            is_conflict_cluster(cluster_id) = true;
        end
    end

    if mod(cluster_id, 500) == 0 || cluster_id == num_clusters
        fprintf("checked %d / %d clusters (%.1f%%), time %.1f sec\n", ...
            cluster_id, num_clusters, 100 * cluster_id / num_clusters, toc(conflict_tic));
    end
end

conflict_clusters = find(is_conflict_cluster);
clean_clusters = find(~is_conflict_cluster);

fprintf("Found %d conflict clusters\n", numel(conflict_clusters));
fprintf("Conflict check took %.1f seconds\n", toc(conflict_tic));

%% make groups from the clean clusters

fprintf("\nMaking groups from the clean part of the matrix...\n");
group_tic = tic;

clean_links = links(clean_clusters, clean_clusters);
G = graph(clean_links);
component_number = conncomp(G);
component_ids = unique(component_number);

remove_conflicts_groups = cell(numel(component_ids) + numel(conflict_clusters), 1);
group_count = 0;

for i = 1:numel(component_ids)
    group_count = group_count + 1;
    members_in_clean_list = component_number == component_ids(i);
    remove_conflicts_groups{group_count} = clean_clusters(members_in_clean_list);
end

% Add every conflict cluster back as its own group. This keeps the cluster in
% the result, but it does not let it contaminate a larger group.
for i = 1:numel(conflict_clusters)
    group_count = group_count + 1;
    remove_conflicts_groups{group_count} = conflict_clusters(i);
end

fprintf("Made %d remove_conflicts groups\n", numel(remove_conflicts_groups));
fprintf("Grouping took %.1f seconds\n", toc(group_tic));

%% summarize every group

fprintf("\nSummarizing groups...\n");
summary_tic = tic;

group_id = (1:numel(remove_conflicts_groups)).';
group_size = zeros(numel(remove_conflicts_groups), 1);
num_units = zeros(numel(remove_conflicts_groups), 1);
dominant_unit = nan(numel(remove_conflicts_groups), 1);
purity = zeros(numel(remove_conflicts_groups), 1);
is_pure = false(numel(remove_conflicts_groups), 1);
unit_list = cell(numel(remove_conflicts_groups), 1);

for g = 1:numel(remove_conflicts_groups)
    members = remove_conflicts_groups{g};
    units_here = max_overlap_unit(members);
    units_here_unique = unique(units_here);
    counts = zeros(numel(units_here_unique), 1);

    for u = 1:numel(units_here_unique)
        counts(u) = sum(units_here == units_here_unique(u));
    end

    [biggest_count, biggest_idx] = max(counts);

    group_size(g) = numel(members);
    num_units(g) = numel(units_here_unique);
    dominant_unit(g) = units_here_unique(biggest_idx);
    purity(g) = biggest_count / numel(members);
    is_pure(g) = numel(units_here_unique) == 1;
    unit_list{g} = units_here_unique(:).';
end

group_summary = table(group_id, group_size, num_units, dominant_unit, purity, is_pure, unit_list);

%% summarize every unit

unit_id = unique_units(:);
groups_with_unit = zeros(numel(unit_id), 1);
clean_group_count = zeros(numel(unit_id), 1);
perfectly_contained = false(numel(unit_id), 1);
clusters_for_unit = zeros(numel(unit_id), 1);

for u = 1:numel(unit_id)
    this_unit = unit_id(u);
    touched_groups = [];

    for g = 1:numel(remove_conflicts_groups)
        members = remove_conflicts_groups{g};
        units_here = max_overlap_unit(members);

        if any(units_here == this_unit)
            touched_groups(end + 1) = g; %#ok<AGROW>
            clusters_for_unit(u) = clusters_for_unit(u) + sum(units_here == this_unit);
        end
    end

    groups_with_unit(u) = numel(touched_groups);
    clean_group_count(u) = sum(is_pure(touched_groups));

    if numel(touched_groups) == 1
        perfectly_contained(u) = is_pure(touched_groups);
    end
end

unit_summary = table(unit_id, groups_with_unit, clean_group_count, perfectly_contained, clusters_for_unit);

fprintf("Summary took %.1f seconds\n", toc(summary_tic));

%% print the main numbers

total_groups = height(group_summary);
total_clusters = sum(group_summary.group_size);
pure_groups = sum(group_summary.is_pure);
contaminated_groups = sum(group_summary.num_units > 1);
clusters_in_pure_groups = sum(group_summary.group_size(group_summary.is_pure));

fprintf("\n--- Remove Conflicts Group Summary ---\n");
fprintf("Total groups:                         %d\n", total_groups);
fprintf("Total clusters:                       %d\n", total_clusters);
fprintf("Mean group size:                      %.1f\n", mean(group_summary.group_size));
fprintf("Median group size:                    %.1f\n", median(group_summary.group_size));
fprintf("Mean purity:                          %.1f%%\n", 100 * mean(group_summary.purity));
fprintf("Median purity:                        %.1f%%\n", 100 * median(group_summary.purity));
fprintf("Groups with purity = 100%%:            %d (%.1f%%)\n", ...
    pure_groups, 100 * pure_groups / total_groups);
fprintf("Groups with purity < 50%%:             %d (%.1f%%)\n", ...
    sum(group_summary.purity < 0.50), 100 * mean(group_summary.purity < 0.50));
fprintf("Groups with >1 unit, contaminated:    %d (%.1f%%)\n", ...
    contaminated_groups, 100 * contaminated_groups / total_groups);
fprintf("Clusters in pure groups:              %d (%.1f%%)\n", ...
    clusters_in_pure_groups, 100 * clusters_in_pure_groups / total_clusters);
fprintf("Largest group size:                   %d\n", max(group_summary.group_size));

fprintf("\n--- Unit Summary ---\n");
fprintf("Total unique units:                   %d\n", height(unit_summary));
fprintf("Fragmented units (>1 group):          %d (%.1f%%)\n", ...
    sum(unit_summary.groups_with_unit > 1), 100 * mean(unit_summary.groups_with_unit > 1));
fprintf("Perfectly contained units:            %d (%.1f%%)\n", ...
    sum(unit_summary.perfectly_contained), 100 * mean(unit_summary.perfectly_contained));
fprintf("Units with at least one clean group:  %d (%.1f%%)\n", ...
    sum(unit_summary.clean_group_count > 0), 100 * mean(unit_summary.clean_group_count > 0));
fprintf("Units with no clean group:            %d (%.1f%%)\n", ...
    sum(unit_summary.clean_group_count == 0), 100 * mean(unit_summary.clean_group_count == 0));

%% show the groups and units worth looking at

bad_groups = group_summary(~group_summary.is_pure, :);
large_groups = sortrows(group_summary, "group_size", "descend");
fragmented_units = unit_summary(unit_summary.groups_with_unit > 1, :);
fragmented_units = sortrows(fragmented_units, "groups_with_unit", "descend");

fprintf("\nFirst contaminated groups, if any\n");
if isempty(bad_groups)
    fprintf("none\n");
else
    disp(bad_groups(1:min(15, height(bad_groups)), :));
end

fprintf("\nLargest groups\n");
disp(large_groups(1:min(15, height(large_groups)), :));

fprintf("\nMost fragmented units\n");
if isempty(fragmented_units)
    fprintf("none\n");
else
    disp(fragmented_units(1:min(15, height(fragmented_units)), :));
end

save(save_file, "remove_conflicts_groups", "conflict_clusters", "clean_clusters", ...
    "group_summary", "unit_summary", "bad_groups", "large_groups", ...
    "fragmented_units", "bp_filtered", "num_merge_pairs", "-v7.3");

fprintf("\nSaved result to:\n%s\n", save_file);
fprintf("Total script time %.1f seconds\n", toc(total_tic));

%%
% What I think i need ti try next
%
% remove_conflicts is doing the safe part well. It gives us a lot of groups,
% but almost all of them are clean. So I do not think the next step should be
% to force groups together just to get closer to 349. That would make the group
% count look better, but it could ruin the thing we care about first: purity.
%
% The next step I would try is a salvage step:
%
% 1. Start with these remove_conflicts groups, because they are the clean pieces.
%
% 2. Compare group against group using the same merge matrix. For two groups, I
%    would count how many s there are between the clusters in group A and the
%    clusters in group B.
%
% 3. Only merge two groups if the evidence is strong. For example, I would want
%    more than one connection between the two groups, and I would not want all
%    the evidence to depend on one unclear cluster.
%
% 4. If a group connects weakly to many different groups, I would leave it alone.
%    That is probably the type of confusing case remove_conflicts is protecting
%    us from.
%
% So the plan is:
%   first keep the clean groups,
%   then carefully recover the obvious split pieces,
%   and only accept merges that do not destroy purity.


% Initialize the salvage groups with the clean groups from remove_conflicts
