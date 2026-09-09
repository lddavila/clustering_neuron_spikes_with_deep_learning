%% Recording 6: test stricter NN probability and support cutoffs
%
% This script does not run the neural network again. It uses the saved merge
% probabilities from step 4 and repeats only the safe grouping step.
%
% Max_Overlap_Unit is used after each grouping result only to measure purity.
% It is not used to decide which groups merge.

clearvars
clc

total_tic = tic;

% The first values reproduce the rule used in step 4. The remaining values
% test increasingly strict versions of that rule.
PROBABILITY_CUTOFFS = [0.95; 0.97; 0.99; 0.995; 0.999; 0.9995];
SUPPORT_CUTOFFS = [0.75; 0.90; 1.00];

script_folder = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(script_folder)));
result_folder = fullfile(repo_root, "Default_Results_Dir", ...
    "recording_6_new_pipeline");

starting_group_file = fullfile(result_folder, ...
    "recording_6_min170_accuracy15_remove_conflicts.mat");
dataset_file = fullfile(result_folder, ...
    "recording_6_complete_nn_test_features.mat");
probability_file = fullfile(result_folder, ...
    "recording_6_nn_pair_probabilities.mat");
save_file = fullfile(result_folder, ...
    "recording_6_stricter_nn_cutoff_results.mat");
figure_file = fullfile(result_folder, ...
    "recording_6_stricter_nn_cutoff_figure.png");

if ~isfile(starting_group_file)
    error("The recording 6 remove_conflicts result was not found.");
end

if ~isfile(dataset_file)
    error("The recording 6 feature dataset was not found.");
end

if ~isfile(probability_file)
    error("Run step_5_apply_trained_nn.m first.");
end

%% Load the starting groups, pair probabilities, and evaluation labels

fprintf("\nLoading the saved recording 6 data...\n");
load_tic = tic;

group_result = load(starting_group_file, "remove_conflicts_groups", ...
    "kept_row_indices", "input_file", "grouping_summary");
probability_info = load(probability_file, "scoring_complete", ...
    "number_of_pairs", "source_dataset_file");

if ~probability_info.scoring_complete
    error("The neural-network probability file is not complete.");
end

if string(probability_info.source_dataset_file) ~= string(dataset_file)
    error("The probability file belongs to a different feature dataset.");
end

input_result = load(group_result.input_file, "data_to_save");
bp_filtered = input_result.data_to_save(group_result.kept_row_indices, :);

if ~ismember("Max_Overlap_Unit", string(bp_filtered.Properties.VariableNames))
    error("Max_Overlap_Unit is required only for the final evaluation.");
end

starting_groups = group_result.remove_conflicts_groups;
number_of_starting_groups = numel(starting_groups);
number_of_clusters = height(bp_filtered);
max_overlap_unit = bp_filtered{:, "Max_Overlap_Unit"};
retained_units = unique(max_overlap_unit);
number_of_retained_units = numel(retained_units);

dataset = matfile(dataset_file);
probability_data = matfile(probability_file);
pair_group_a = dataset.group_a;
pair_group_b = dataset.group_b;
merge_probability = probability_data.merge_probability;

number_of_pairs = numel(merge_probability);
if number_of_pairs ~= probability_info.number_of_pairs
    error("The probability vector has the wrong number of rows.");
end

fprintf("starting groups:          %d\n", number_of_starting_groups);
fprintf("retained clusters:        %d\n", number_of_clusters);
fprintf("retained unique units:    %d\n", number_of_retained_units);
fprintf("saved pair probabilities: %d\n", number_of_pairs);
fprintf("cutoff combinations:      %d\n", ...
    numel(PROBABILITY_CUTOFFS) * numel(SUPPORT_CUTOFFS));
fprintf("loading took %.1f seconds\n", toc(load_tic));

clear input_result bp_filtered probability_info

%% Build the symmetric group-pair probability matrix once

fprintf("\nBuilding the group-pair probability matrix...\n");
matrix_tic = tic;

probability_matrix = zeros(number_of_starting_groups, ...
    number_of_starting_groups, "single");
matrix_batch_size = 500000;

for batch_start = 1:matrix_batch_size:number_of_pairs
    batch_end = min(batch_start + matrix_batch_size - 1, number_of_pairs);
    batch_rows = batch_start:batch_end;
    group_a_here = double(pair_group_a(batch_rows));
    group_b_here = double(pair_group_b(batch_rows));
    matrix_rows = group_a_here + ...
        (group_b_here - 1) * number_of_starting_groups;
    probability_matrix(matrix_rows) = merge_probability(batch_rows);
end

probability_matrix = probability_matrix + probability_matrix.';
probability_matrix(1:number_of_starting_groups + 1:end) = 1;

fprintf("probability matrix took %.1f seconds\n", toc(matrix_tic));

%% Try every probability and support combination

fprintf("\nTesting stricter grouping rules...\n");
grid_tic = tic;

number_of_results = numel(PROBABILITY_CUTOFFS) * numel(SUPPORT_CUTOFFS);
result_number = 0;
cutoff_summary = table();
all_groups = cell(number_of_results, 1);
all_group_summaries = cell(number_of_results, 1);
all_unit_summaries = cell(number_of_results, 1);

for probability_number = 1:numel(PROBABILITY_CUTOFFS)
    probability_cutoff = PROBABILITY_CUTOFFS(probability_number);
    candidate_rows = find(merge_probability >= probability_cutoff);
    [~, candidate_order] = sort(merge_probability(candidate_rows), "descend");
    candidate_rows = candidate_rows(candidate_order);

    for support_number = 1:numel(SUPPORT_CUTOFFS)
        result_number = result_number + 1;
        support_cutoff = SUPPORT_CUTOFFS(support_number);
        rule_tic = tic;

        component_for_group = (1:number_of_starting_groups).';
        component_members = num2cell((1:number_of_starting_groups).');
        component_is_alive = true(number_of_starting_groups, 1);
        safe_merges = 0;

        % Candidate links are checked from the highest NN probability to the
        % lowest. Two current components merge only if enough of all their
        % cross-comparisons pass the same probability cutoff.
        for candidate_number = 1:numel(candidate_rows)
            pair_row = candidate_rows(candidate_number);
            left_group = double(pair_group_a(pair_row));
            right_group = double(pair_group_b(pair_row));
            left_component = component_for_group(left_group);
            right_component = component_for_group(right_group);

            if left_component ~= right_component
                left_members = component_members{left_component};
                right_members = component_members{right_component};
                cross_probabilities = ...
                    probability_matrix(left_members, right_members);
                cross_support = mean( ...
                    cross_probabilities(:) >= probability_cutoff);

                if cross_support >= support_cutoff
                    component_members{left_component} = ...
                        [left_members(:); right_members(:)];
                    component_members{right_component} = [];
                    component_for_group(right_members) = left_component;
                    component_is_alive(right_component) = false;
                    safe_merges = safe_merges + 1;
                end
            end
        end

        alive_components = find(component_is_alive);
        groups = cell(numel(alive_components), 1);

        for final_group_id = 1:numel(alive_components)
            starting_group_ids = ...
                component_members{alive_components(final_group_id)};
            cluster_members = [];

            for member_number = 1:numel(starting_group_ids)
                cluster_members = [cluster_members; ...
                    starting_groups{starting_group_ids(member_number)}(:)]; %#ok<AGROW>
            end

            groups{final_group_id} = unique(cluster_members);
        end

        number_of_groups = numel(groups);
        all_group_members = sort(vertcat(groups{:}));
        if ~isequal(all_group_members, (1:number_of_clusters).')
            error("A cutoff result is missing clusters or contains duplicates.");
        end

        %% Evaluate this result after grouping is complete

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
            members = groups{current_group};
            units_here = max_overlap_unit(members);
            unique_units_here = unique(units_here);
            unit_counts = zeros(numel(unique_units_here), 1);

            for unit_number = 1:numel(unique_units_here)
                unit_counts(unit_number) = ...
                    sum(units_here == unique_units_here(unit_number));
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

        group_summary = table(group_id, group_size, num_units, dominant_unit, ...
            dominant_cluster_count, purity, is_pure, ...
            contaminating_cluster_count, unit_list);

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

        unit_summary = table(unit_id, groups_with_unit, clean_group_count, ...
            perfectly_contained, clusters_for_unit);

        pure_groups = sum(is_pure);
        contaminated_groups = sum(~is_pure);
        groups_per_unit_ratio = number_of_groups / number_of_retained_units;
        fully_pure_group_percent = 100 * pure_groups / number_of_groups;
        mean_group_purity_percent = 100 * mean(purity);
        clusters_in_pure_percent = ...
            100 * sum(group_size(is_pure)) / number_of_clusters;
        fragmented_units = sum(groups_with_unit > 1);
        perfectly_contained_units = sum(perfectly_contained);
        units_with_clean_group = sum(clean_group_count > 0);

        result_row = table(result_number, probability_cutoff, support_cutoff, ...
            numel(candidate_rows), safe_merges, number_of_groups, ...
            number_of_retained_units, groups_per_unit_ratio, pure_groups, ...
            fully_pure_group_percent, mean_group_purity_percent, ...
            clusters_in_pure_percent, contaminated_groups, max(group_size), ...
            fragmented_units, perfectly_contained_units, ...
            units_with_clean_group, ...
            'VariableNames', {'result_id', 'probability_cutoff', ...
            'support_cutoff', 'candidate_links', 'safe_merges', 'num_groups', ...
            'num_unique_units', 'groups_per_unit_ratio', 'pure_groups', ...
            'fully_pure_group_percent', 'mean_group_purity_percent', ...
            'clusters_in_pure_percent', 'contaminated_groups', ...
            'largest_group_size', 'fragmented_units', ...
            'perfectly_contained_units', 'units_with_clean_group'});

        cutoff_summary = [cutoff_summary; result_row]; %#ok<AGROW>
        all_groups{result_number} = groups;
        all_group_summaries{result_number} = group_summary;
        all_unit_summaries{result_number} = unit_summary;

        fprintf("prob %.4f | support %.2f | groups %4d | ratio %.3f | " + ...
            "fully pure %.2f%% | clusters pure %.2f%% | bad %3d | %.1f sec\n", ...
            probability_cutoff, support_cutoff, number_of_groups, ...
            groups_per_unit_ratio, fully_pure_group_percent, ...
            clusters_in_pure_percent, contaminated_groups, toc(rule_tic));
    end
end

fprintf("cutoff grid took %.1f seconds\n", toc(grid_tic));

%% Print the most useful comparisons

fprintf("\nAll stricter cutoff results\n");
disp(cutoff_summary);

% This order puts contamination first, then prefers fewer groups when two
% rules have the same number of contaminated groups.
safest_first = sortrows(cutoff_summary, ...
    ["contaminated_groups", "num_groups", ...
    "clusters_in_pure_percent"], ["ascend", "ascend", "descend"]);

fprintf("\nResults sorted by fewer contaminated groups, then fewer groups\n");
disp(safest_first);

%% Plot group count against the two strict purity measurements

figure("Color", "white", "Position", [100 100 1200 500]);
tiledlayout(1, 2, "Padding", "compact", "TileSpacing", "compact");

colors = lines(numel(SUPPORT_CUTOFFS));

nexttile;
hold on
for support_number = 1:numel(SUPPORT_CUTOFFS)
    rows = cutoff_summary.support_cutoff == SUPPORT_CUTOFFS(support_number);
    plot(cutoff_summary.num_groups(rows), ...
        cutoff_summary.fully_pure_group_percent(rows), "-o", ...
        "LineWidth", 1.5, "MarkerSize", 6, ...
        "Color", colors(support_number, :), ...
        "DisplayName", sprintf("support %.2f", ...
        SUPPORT_CUTOFFS(support_number)));

    labels = compose("p %.4g", cutoff_summary.probability_cutoff(rows));
    text(cutoff_summary.num_groups(rows), ...
        cutoff_summary.fully_pure_group_percent(rows), labels, ...
        "FontSize", 8, "VerticalAlignment", "bottom");
end
xline(number_of_retained_units, "--", "524 retained units");
xlabel("Number of groups");
ylabel("Fully pure groups (%)");
title("Recording 6: fully pure groups");
grid on
legend("Location", "best");
hold off

nexttile;
hold on
for support_number = 1:numel(SUPPORT_CUTOFFS)
    rows = cutoff_summary.support_cutoff == SUPPORT_CUTOFFS(support_number);
    plot(cutoff_summary.num_groups(rows), ...
        cutoff_summary.clusters_in_pure_percent(rows), "-o", ...
        "LineWidth", 1.5, "MarkerSize", 6, ...
        "Color", colors(support_number, :), ...
        "DisplayName", sprintf("support %.2f", ...
        SUPPORT_CUTOFFS(support_number)));

    labels = compose("p %.4g", cutoff_summary.probability_cutoff(rows));
    text(cutoff_summary.num_groups(rows), ...
        cutoff_summary.clusters_in_pure_percent(rows), labels, ...
        "FontSize", 8, "VerticalAlignment", "bottom");
end
xline(number_of_retained_units, "--", "524 retained units");
xlabel("Number of groups");
ylabel("Clusters in completely pure groups (%)");
title("Recording 6: clusters protected from contamination");
grid on
legend("Location", "best");
hold off

exportgraphics(gcf, figure_file, "Resolution", 200);

%% Save every result for later inspection

source_probability_file = probability_file;
source_starting_group_file = starting_group_file;
total_seconds = toc(total_tic);

save(save_file, "cutoff_summary", "safest_first", "all_groups", ...
    "all_group_summaries", "all_unit_summaries", ...
    "PROBABILITY_CUTOFFS", "SUPPORT_CUTOFFS", ...
    "source_probability_file", "source_starting_group_file", ...
    "number_of_clusters", "number_of_retained_units", ...
    "total_seconds", "-v7.3");

fprintf("\nsaved cutoff results to:\n%s\n", save_file);
fprintf("saved figure to:\n%s\n", figure_file);
fprintf("total script time: %.1f seconds\n", total_seconds);
