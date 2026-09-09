%%
% Euclidean distance grouping test.
%
% Start with the remove_conflicts groups.
% Then merge groups when their average waveforms are close enough.
%
% The grouping rule is:
%
%   small Euclidean distance = merge
%
% Max_Overlap_Unit is only used at the end to check the result.
% basically:
%   one average waveform for group A
%   one average waveform for group B
%         compare those two
% this is not doing:
% every cluster in group A compared to every cluster in group B


clear
clc

total_tic = tic;

script_folder = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(script_folder)));
addpath(genpath(repo_root), "-begin");

remove_conflicts_file = fullfile(repo_root, "Default_Results_Dir", "remove_conflicts_only_result.mat");
save_file = fullfile(repo_root, "Default_Results_Dir", "simple_euclidean_only_grouping_result.mat");

% Smaller cutoff means stricter.
% merge two groups if their waveform distance is <= this number
DISTANCE_CUTOFFS = [2; 4; 6; 8; 10; 12; 15; 20; 25; 30; 35; 40; 50; 60; 80; 100; 120];

if ~isfile(remove_conflicts_file)
    error("Run step_1_make_remove_conflicts_groups.m first.");
end

fprintf("\nLoading data...\n");
S = load(remove_conflicts_file, "remove_conflicts_groups", "bp_filtered");

old_groups = S.remove_conflicts_groups;
bp_filtered = S.bp_filtered;

num_clusters = height(bp_filtered);
num_old_groups = numel(old_groups);

fprintf("clusters: %d\n", num_clusters);
fprintf("starting groups: %d\n", num_old_groups);
fprintf("cutoffs to test: %d\n", numel(DISTANCE_CUTOFFS));

%% making one average waveform for each old group

fprintf("\nMaking average waveforms...\n");
setup_tic = tic;

all_waveforms = cell2mat(bp_filtered{:, "mean_waveform_rep_wire_1"});
group_waveforms = zeros(num_old_groups, size(all_waveforms, 2));

for g = 1:num_old_groups
    members = old_groups{g};
    group_waveforms(g, :) = mean(all_waveforms(members, :), 1);
end

fprintf("waveform setup took %.1f seconds\n", toc(setup_tic));

%% compare every pair of groups by Euclidean distance

fprintf("\nComparing group waveforms...\n");
compare_tic = tic;

[group_a, group_b] = find(triu(true(num_old_groups), 1));
num_pairs = numel(group_a);

waveform_distance = zeros(num_pairs, 1);

for p = 1:num_pairs
    a = group_a(p);
    b = group_b(p);
% the actual formula
    waveform_distance(p) = sqrt(sum((group_waveforms(a, :) - group_waveforms(b, :)).^2));
% checkpoint printing
    if mod(p, 250000) == 0 || p == num_pairs
        fprintf("checked %d / %d pairs (%.1f%%), time %.1f sec\n", ...
            p, num_pairs, 100 * p / num_pairs, toc(compare_tic));
    end
end

fprintf("waveform comparison took %.1f seconds\n", toc(compare_tic));

%% try each distance cutoff and printing the summary

fprintf("\nTesting distance cutoffs...\n");
test_tic = tic;

max_overlap_unit = bp_filtered{:, "Max_Overlap_Unit"};
unique_units = unique(max_overlap_unit);

num_groups = zeros(numel(DISTANCE_CUTOFFS), 1);
pure_groups = zeros(numel(DISTANCE_CUTOFFS), 1);
purity_percent = zeros(numel(DISTANCE_CUTOFFS), 1);
clusters_in_pure_percent = zeros(numel(DISTANCE_CUTOFFS), 1);
contaminated_groups = zeros(numel(DISTANCE_CUTOFFS), 1);
largest_group_size = zeros(numel(DISTANCE_CUTOFFS), 1);
waveform_links = zeros(numel(DISTANCE_CUTOFFS), 1);
fragmented_units = zeros(numel(DISTANCE_CUTOFFS), 1);
perfectly_contained_units = zeros(numel(DISTANCE_CUTOFFS), 1);
units_with_clean_group = zeros(numel(DISTANCE_CUTOFFS), 1);

all_group_summaries = cell(numel(DISTANCE_CUTOFFS), 1);

for c = 1:numel(DISTANCE_CUTOFFS)
    distance_link = waveform_distance <= DISTANCE_CUTOFFS(c);
    waveform_links(c) = sum(distance_link);

    G = graph(group_a(distance_link), group_b(distance_link), [], num_old_groups);
    component_number = conncomp(G);
    component_ids = unique(component_number);

    group_id = (1:numel(component_ids)).';
    group_size = zeros(numel(component_ids), 1);
    num_units = zeros(numel(component_ids), 1);
    dominant_unit = nan(numel(component_ids), 1);
    purity = zeros(numel(component_ids), 1);
    is_pure = false(numel(component_ids), 1);
    unit_list = cell(numel(component_ids), 1);
    cluster_to_group = zeros(num_clusters, 1);

    for g = 1:numel(component_ids)
        old_group_ids = find(component_number == component_ids(g));
        members = [];

        for j = 1:numel(old_group_ids)
            members = [members; old_groups{old_group_ids(j)}(:)]; %#ok<AGROW>
        end

        members = unique(members);
        units_here = max_overlap_unit(members);
        units_unique = unique(units_here);
        counts = zeros(numel(units_unique), 1);

        for u = 1:numel(units_unique)
            counts(u) = sum(units_here == units_unique(u));
        end

        [biggest_count, biggest_idx] = max(counts);

        group_size(g) = numel(members);
        num_units(g) = numel(units_unique);
        dominant_unit(g) = units_unique(biggest_idx);
        purity(g) = biggest_count / numel(members);
        is_pure(g) = numel(units_unique) == 1;
        unit_list{g} = units_unique(:).';
        cluster_to_group(members) = g;
    end

    group_summary = table(group_id, group_size, num_units, dominant_unit, purity, is_pure, unit_list);
    all_group_summaries{c} = group_summary;

    groups_with_unit = zeros(numel(unique_units), 1);
    clean_group_count = zeros(numel(unique_units), 1);
    perfectly_contained = false(numel(unique_units), 1);

    for u = 1:numel(unique_units)
        unit_clusters = find(max_overlap_unit == unique_units(u));
        touched_groups = unique(cluster_to_group(unit_clusters));

        groups_with_unit(u) = numel(touched_groups);
        clean_group_count(u) = sum(is_pure(touched_groups));
        perfectly_contained(u) = numel(touched_groups) == 1 && clean_group_count(u) == 1;
    end

    num_groups(c) = height(group_summary);
    pure_groups(c) = sum(is_pure);
    purity_percent(c) = 100 * pure_groups(c) / num_groups(c);
    clusters_in_pure_percent(c) = 100 * sum(group_size(is_pure)) / num_clusters;
    contaminated_groups(c) = sum(~is_pure);
    largest_group_size(c) = max(group_size);
    fragmented_units(c) = sum(groups_with_unit > 1);
    perfectly_contained_units(c) = sum(perfectly_contained);
    units_with_clean_group(c) = sum(clean_group_count > 0);

    fprintf("cutoff %5.1f | links %7d | groups %4d | pure %.1f%% | clusters pure %.1f%%\n", ...
        DISTANCE_CUTOFFS(c), waveform_links(c), num_groups(c), ...
        purity_percent(c), clusters_in_pure_percent(c));
end

cutoff_summary = table(DISTANCE_CUTOFFS, waveform_links, num_groups, pure_groups, ...
    purity_percent, clusters_in_pure_percent, contaminated_groups, ...
    largest_group_size, fragmented_units, perfectly_contained_units, ...
    units_with_clean_group);

fprintf("cutoff testing took %.1f seconds\n", toc(test_tic));

fprintf("\nEuclidean-only cutoff summary\n");
disp(cutoff_summary);

%% plots

figure;

yyaxis left
plot(DISTANCE_CUTOFFS, num_groups, "-o", "LineWidth", 1.5);
ylabel("number of groups");

yyaxis right
plot(DISTANCE_CUTOFFS, purity_percent, "-o", "LineWidth", 1.5);
ylabel("pure groups (%)");

xlabel("Euclidean distance cutoff");
title("Euclidean-only cutoff test");
grid on

figure;
plot(num_groups, purity_percent, "-o", "LineWidth", 1.5);
xlabel("number of groups");
ylabel("pure groups (%)");
title("Euclidean-only purity vs number of groups");
grid on
hold on
xline(349, "--", "349 units", "LineWidth", 1.5);
plot(349, 100, "p", "MarkerSize", 16, "MarkerFaceColor", "red", "MarkerEdgeColor", "black");
text(349, 100, " ideal (349, 100%)", "FontWeight", "bold");

for c = 1:numel(DISTANCE_CUTOFFS)
    text(num_groups(c), purity_percent(c), " " + string(DISTANCE_CUTOFFS(c)));
end

hold off

save(save_file, "cutoff_summary", "waveform_distance", "group_a", "group_b", ...
    "all_group_summaries", "DISTANCE_CUTOFFS");

fprintf("\nsaved result to:\n%s\n", save_file);
fprintf("total time %.1f seconds\n", toc(total_tic));

%% notes
%
% This only uses euclidean distance between average group waveforms.
%
% A small cutoff is stricter. A large cutoff merges more groups, but can also
% create mixed groups.


% perhaps the results look weird because i am using connected componets, so:
%   when
% A links to B
% B links to C
% A does not link to C
% Connected components will still merge all three.
%
% some other things i could try are:

% ------ All-to-all group rule
% Only merge pieces into one group if every old group inside
%  that final group is close to every other old group.

% ------ Pair-only merging
% Only merge direct pairs that pass the cutoff,
% but do not allow long chains to keep growing freely.
% This is simpler but may leave many fragments.

% ------ Bridge dropping
% First build connected components, then inspect
%  each big group and remove weak bridge links.

% ------ Also, instead of one average waveform per group,
%  compare all cluster waveforms between two groups,
% then use mean/median distance
%  This gives a stronger score before deciding to merge.



%% purity_percent
% A group is clean/pure if all clusters inside it have the same Max_Overlap_Unit.
% example: 100 total groups, 95 pure groups, therefore 95% purity

% clusters_in_pure_percent means:
% percentage of all clusters are inside clean groups, example:
% 4936 total clusters
% 4800 clusters are inside pure groups
% clusters_in_pure_percent = 4800 / 4936 = 97.2%

% so if:
% 99 tiny groups are pure
% 1 huge group is contaminated
% purity 99 / 100 = 99%
% Then purity_percent may look great (99%),
% but if the huge contaminated group contains most of the clusters,
% clusters_in_pure_percent will look bad.
