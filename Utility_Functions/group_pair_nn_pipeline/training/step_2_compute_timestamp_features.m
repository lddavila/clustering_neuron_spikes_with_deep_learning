%%
% Timestamp grouping test with a reciprocal overlap check.
%
% Start with the remove_conflicts groups.
% First use the normal timestamp rule:
%
%   most of the smaller group has to overlap the bigger group
%
% Then add one extra rule:
%
%   the matched timestamps also have to cover enough of the bigger group
%
% Example:
% If one group has 1000 timestamps, then a 10% reciprocal cutoff means we need
% about 100 matched timestamps from the bigger group's side too. This keeps a
% tiny group from joining a much bigger group just because the tiny group fits
% inside it.
%
% Max_Overlap_Unit is only used at the end to check the result.

clear
clc

total_tic = tic;

script_folder = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(script_folder)));
addpath(genpath(repo_root), "-begin");

remove_conflicts_file = fullfile(repo_root, "Default_Results_Dir", "remove_conflicts_only_result.mat");
save_file = fullfile(repo_root, "Default_Results_Dir", "simple_timestamp_reciprocal_grouping_result.mat");

% This is the normal timestamp-only cutoff.
% Higher means stricter.
TIMESTAMP_CUTOFF = 90;

% This is the new extra rule.
% 0 means normal timestamp-only. Higher values make it harder for a small group
% to merge into a much bigger group.
RECIPROCAL_CUTOFFS = [0; 2.5; 5; 7.5; 10; 12.5; 15; 20; 25; 30; 40; 50];

if ~isfile(remove_conflicts_file)
    error("Run step_1_make_remove_conflicts_groups.m first.");
end

fprintf("\nLoading data...\n");
load_tic = tic;

S = load(remove_conflicts_file, "remove_conflicts_groups", "bp_filtered");

old_groups = S.remove_conflicts_groups;
bp_filtered = S.bp_filtered;

config = spikesort_config();
time_delta = config.TIME_DELTA;

num_clusters = height(bp_filtered);
num_old_groups = numel(old_groups);

fprintf("clusters: %d\n", num_clusters);
fprintf("starting groups: %d\n", num_old_groups);
fprintf("normal timestamp cutoff: %.1f%%\n", TIMESTAMP_CUTOFF);
fprintf("reciprocal cutoffs to test: %d\n", numel(RECIPROCAL_CUTOFFS));
fprintf("loading took %.1f seconds\n", toc(load_tic));

%% make one timestamp list for each old group

fprintf("\nMaking timestamp lists...\n");
setup_tic = tic;

timestamps_col = bp_filtered{:, "timestamps"};
cluster_timestamps = cell(num_clusters, 1);

for i = 1:num_clusters
    ts = timestamps_col{i};

    if iscell(ts)
        ts = ts{1};
    end

    cluster_timestamps{i} = ts(:);
end

group_timestamps = cell(num_old_groups, 1);

for g = 1:num_old_groups
    members = old_groups{g};
    ts_for_group = [];

    for j = 1:numel(members)
        ts_for_group = [ts_for_group; cluster_timestamps{members(j)}]; %#ok<AGROW>
    end

    group_timestamps{g} = unique(sort(ts_for_group));
end

fprintf("timestamp setup took %.1f seconds\n", toc(setup_tic));

%% compare every pair of groups by timestamp overlap

fprintf("\nComparing group timestamps...\n");
compare_tic = tic;

[group_a, group_b] = find(triu(true(num_old_groups), 1));
num_pairs = numel(group_a);

smaller_overlap_percent = zeros(num_pairs, 1);
reciprocal_overlap_percent = zeros(num_pairs, 1);
matched_timestamps = zeros(num_pairs, 1);
smaller_timestamp_count = zeros(num_pairs, 1);
larger_timestamp_count = zeros(num_pairs, 1);

for p = 1:num_pairs
    a = group_a(p);
    b = group_b(p);

    ts_a = group_timestamps{a};
    ts_b = group_timestamps{b};

    smaller_timestamp_count(p) = min(numel(ts_a), numel(ts_b));
    larger_timestamp_count(p) = max(numel(ts_a), numel(ts_b));

    if smaller_timestamp_count(p) == 0
        smaller_overlap_percent(p) = 0;
        reciprocal_overlap_percent(p) = 0;
        matched_timestamps(p) = 0;
    else
        [small_overlap, ~, matches] = find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs( ...
            ts_a, ts_b, time_delta);

        smaller_overlap_percent(p) = 100 * small_overlap;
        reciprocal_overlap_percent(p) = 100 * matches / larger_timestamp_count(p);
        matched_timestamps(p) = matches;
    end

    if mod(p, 100000) == 0 || p == num_pairs
        fprintf("checked %d / %d pairs (%.1f%%), time %.1f sec\n", ...
            p, num_pairs, 100 * p / num_pairs, toc(compare_tic));
    end
end

fprintf("timestamp comparison took %.1f seconds\n", toc(compare_tic));

%% compare normal timestamp-only with timestamp + reciprocal overlap

fprintf("\nTesting reciprocal overlap cutoffs...\n");
test_tic = tic;

normal_timestamp_link = smaller_overlap_percent >= TIMESTAMP_CUTOFF;
normal_timestamp_links = sum(normal_timestamp_link);

fprintf("normal timestamp-only links: %d\n", normal_timestamp_links);

max_overlap_unit = bp_filtered{:, "Max_Overlap_Unit"};
unique_units = unique(max_overlap_unit);

reciprocal_cutoff = RECIPROCAL_CUTOFFS;
accepted_links = zeros(numel(reciprocal_cutoff), 1);
num_groups = zeros(numel(reciprocal_cutoff), 1);
pure_groups = zeros(numel(reciprocal_cutoff), 1);
purity_percent = zeros(numel(reciprocal_cutoff), 1);
clusters_in_pure_percent = zeros(numel(reciprocal_cutoff), 1);
contaminated_groups = zeros(numel(reciprocal_cutoff), 1);
largest_group_size = zeros(numel(reciprocal_cutoff), 1);
fragmented_units = zeros(numel(reciprocal_cutoff), 1);
perfectly_contained_units = zeros(numel(reciprocal_cutoff), 1);
units_with_clean_group = zeros(numel(reciprocal_cutoff), 1);

all_reciprocal_groups = cell(numel(reciprocal_cutoff), 1);

for c = 1:numel(reciprocal_cutoff)
    timestamp_link = normal_timestamp_link & reciprocal_overlap_percent >= reciprocal_cutoff(c);
    accepted_links(c) = sum(timestamp_link);

    G = graph(group_a(timestamp_link), group_b(timestamp_link), [], num_old_groups);
    component_number = conncomp(G);
    component_ids = unique(component_number);

    reciprocal_groups = cell(numel(component_ids), 1);
    group_is_pure = false(numel(component_ids), 1);
    group_size = zeros(numel(component_ids), 1);
    cluster_to_group = zeros(num_clusters, 1);

    for g = 1:numel(component_ids)
        old_group_ids = find(component_number == component_ids(g));
        members = [];

        for j = 1:numel(old_group_ids)
            members = [members; old_groups{old_group_ids(j)}(:)]; %#ok<AGROW>
        end

        members = unique(members);
        units_here = max_overlap_unit(members);

        reciprocal_groups{g} = members;
        group_is_pure(g) = numel(unique(units_here)) == 1;
        group_size(g) = numel(members);
        cluster_to_group(members) = g;
    end

    groups_with_unit = zeros(numel(unique_units), 1);
    clean_group_count = zeros(numel(unique_units), 1);
    perfectly_contained = false(numel(unique_units), 1);

    for u = 1:numel(unique_units)
        unit_clusters = find(max_overlap_unit == unique_units(u));
        touched_groups = unique(cluster_to_group(unit_clusters));

        groups_with_unit(u) = numel(touched_groups);
        clean_group_count(u) = sum(group_is_pure(touched_groups));
        perfectly_contained(u) = numel(touched_groups) == 1 && clean_group_count(u) == 1;
    end

    all_reciprocal_groups{c} = reciprocal_groups;
    num_groups(c) = numel(reciprocal_groups);
    pure_groups(c) = sum(group_is_pure);
    purity_percent(c) = 100 * pure_groups(c) / num_groups(c);
    clusters_in_pure_percent(c) = 100 * sum(group_size(group_is_pure)) / num_clusters;
    contaminated_groups(c) = sum(~group_is_pure);
    largest_group_size(c) = max(group_size);
    fragmented_units(c) = sum(groups_with_unit > 1);
    perfectly_contained_units(c) = sum(perfectly_contained);
    units_with_clean_group(c) = sum(clean_group_count > 0);

    fprintf("reciprocal >= %4.1f%% | links %6d | groups %4d | pure %.1f%% | clusters pure %.1f%%\n", ...
        reciprocal_cutoff(c), accepted_links(c), num_groups(c), ...
        purity_percent(c), clusters_in_pure_percent(c));
end

reciprocal_summary = table(reciprocal_cutoff, accepted_links, num_groups, ...
    pure_groups, purity_percent, clusters_in_pure_percent, contaminated_groups, ...
    largest_group_size, fragmented_units, perfectly_contained_units, ...
    units_with_clean_group);

fprintf("cutoff testing took %.1f seconds\n", toc(test_tic));

fprintf("\nTimestamp + reciprocal overlap summary\n");
disp(reciprocal_summary);

%% plot the comparison

normal_groups = num_groups(reciprocal_cutoff == 0);
normal_purity = purity_percent(reciprocal_cutoff == 0);

figure;

subplot(1, 2, 1)
plot(reciprocal_cutoff, num_groups, "-o", "LineWidth", 1.5);
hold on
yline(normal_groups, "--", "timestamp only", "LineWidth", 1.2);
hold off
xlabel("reciprocal overlap cutoff (%)");
ylabel("number of groups");
title("Group count");
grid on

subplot(1, 2, 2)
plot(reciprocal_cutoff, purity_percent, "-o", "LineWidth", 1.5);
hold on
yline(normal_purity, "--", "timestamp only", "LineWidth", 1.2);
hold off
xlabel("reciprocal overlap cutoff (%)");
ylabel("pure groups (%)");
title("Purity");
grid on

sgtitle("Timestamp-only vs reciprocal timestamp overlap");

%% tradeoff plot

figure;
plot(num_groups, purity_percent, "-o", "LineWidth", 1.5);
hold on
plot(normal_groups, normal_purity, "s", "MarkerSize", 10, ...
    "MarkerFaceColor", "black", "MarkerEdgeColor", "black");
xline(349, "--", "349 units", "LineWidth", 1.5);
plot(349, 100, "p", "MarkerSize", 16, "MarkerFaceColor", "red", "MarkerEdgeColor", "black");
text(349, 100, " ideal (349, 100%)", "FontWeight", "bold");

for c = 1:numel(reciprocal_cutoff)
    text(num_groups(c), purity_percent(c), " " + string(reciprocal_cutoff(c)) + "%");
end

hold off
xlabel("number of groups");
ylabel("pure groups (%)");
title("Reciprocal timestamp overlap tradeoff");
grid on

if isfile(save_file)
    delete(save_file);
end

save(save_file, "all_reciprocal_groups", "reciprocal_summary", ...
    "TIMESTAMP_CUTOFF", "RECIPROCAL_CUTOFFS", "smaller_overlap_percent", ...
    "reciprocal_overlap_percent", "matched_timestamps", ...
    "smaller_timestamp_count", "larger_timestamp_count", "group_a", "group_b", "-v7.3");

fprintf("\nsaved result to:\n%s\n", save_file);
fprintf("total time %.1f seconds\n", toc(total_tic));

%%
% Notes
%
% The normal timestamp score checks whether the smaller group mostly fits into
% the bigger group.
%
% The reciprocal score checks how much of the bigger group is covered by the
% matched timestamps.
%
% A higher reciprocal cutoff should usually make fewer merges. That can give
% more groups, but it may also protect purity by blocking tiny groups from
% joining much bigger groups too easily.
