function result = run_one_accuracy_cutoff(accuracy_cutoff, bp, ...
        base_row_indices, base_merge_matrix, final_net, feature_mean, ...
        feature_std, probability_cutoff, support_cutoff, config, ...
        number_of_workers)
% Run the complete nine-feature grouping test for one accuracy filter.

cutoff_tic = tic;

%% Keep the clusters for this cutoff and extract their council matrix

base_accuracy = bp{base_row_indices, "accuracy"};
base_positions_kept = find(base_accuracy >= accuracy_cutoff);
kept_row_indices = base_row_indices(base_positions_kept);
bp_filtered = bp(kept_row_indices, :);
merge_matrix = logical(base_merge_matrix( ...
    base_positions_kept, base_positions_kept));

number_of_clusters = height(bp_filtered);
max_overlap_unit = bp_filtered{:, "Max_Overlap_Unit"};
number_of_units = numel(unique(max_overlap_unit));
number_of_original_units = numel(unique(bp{:, "Max_Overlap_Unit"}));

fprintf("\n============================================================\n");
fprintf("accuracy cutoff: %.0f percent\n", accuracy_cutoff);
fprintf("clusters kept:   %d\n", number_of_clusters);
fprintf("units retained:  %d / %d\n", ...
    number_of_units, number_of_original_units);

%% Start with remove_conflicts, exactly as in the recording 6 pipeline

fprintf("making remove_conflicts groups...\n");
group_tic = tic;
remove_conflicts_groups = make_remove_conflicts_groups(merge_matrix);
number_of_starting_groups = numel(remove_conflicts_groups);

fprintf("remove_conflicts groups: %d\n", number_of_starting_groups);
fprintf("remove_conflicts took %.1f seconds\n", toc(group_tic));

%% Build the group information used by the nine features

fprintf("preparing group features...\n");
feature_tic = tic;

timestamp_column = bp_filtered{:, "timestamps"};
cluster_timestamps = cell(number_of_clusters, 1);
for cluster_id = 1:number_of_clusters
    timestamps = timestamp_column{cluster_id};
    if iscell(timestamps)
        timestamps = timestamps{1};
    end
    cluster_timestamps{cluster_id} = timestamps(:);
end

group_timestamps = cell(number_of_starting_groups, 1);
group_cluster_count = zeros(number_of_starting_groups, 1);
group_timestamp_count = zeros(number_of_starting_groups, 1);

for group_id = 1:number_of_starting_groups
    members = remove_conflicts_groups{group_id};
    timestamps = unique(sort(vertcat(cluster_timestamps{members})));
    group_timestamps{group_id} = timestamps;
    group_cluster_count(group_id) = numel(members);
    group_timestamp_count(group_id) = numel(timestamps);
end

cluster_waveforms = cell2mat( ...
    bp_filtered{:, "mean_waveform_rep_wire_1"});
group_waveforms = zeros(number_of_starting_groups, ...
    size(cluster_waveforms, 2));

for group_id = 1:number_of_starting_groups
    group_waveforms(group_id, :) = mean( ...
        cluster_waveforms(remove_conflicts_groups{group_id}, :), 1);
end

probe_locations = get_probe_xy();
assembled_repwire = assemble_data_for_neural_net( ...
    "rep_wire", bp_filtered, config);
cluster_repwire = assembled_repwire{1};
cluster_location = probe_locations(cluster_repwire, :);
group_location = zeros(number_of_starting_groups, 2);

for group_id = 1:number_of_starting_groups
    group_location(group_id, :) = mean( ...
        cluster_location(remove_conflicts_groups{group_id}, :), 1);
end

fprintf("group feature setup took %.1f seconds\n", toc(feature_tic));
clear timestamp_column cluster_timestamps cluster_waveforms
clear cluster_location assembled_repwire

%% Score every pair of starting groups with the frozen nine-feature NN

number_of_pairs = number_of_starting_groups * ...
    (number_of_starting_groups - 1) / 2;
group_a = zeros(number_of_pairs, 1, "uint32");
group_b = zeros(number_of_pairs, 1, "uint32");
next_row = 1;

for right_group = 2:number_of_starting_groups
    rows = next_row:(next_row + right_group - 2);
    group_a(rows) = uint32(1:right_group - 1);
    group_b(rows) = uint32(right_group);
    next_row = rows(end) + 1;
end

merge_probability = zeros(number_of_pairs, 1, "single");
batch_size = 100000;
time_delta = config.TIME_DELTA;
normalization_mean = single(feature_mean);
normalization_std = single(feature_std);

fprintf("scoring %d group pairs with the nine-feature NN...\n", ...
    number_of_pairs);
score_tic = tic;

for batch_start = 1:batch_size:number_of_pairs
    batch_end = min(batch_start + batch_size - 1, number_of_pairs);
    batch_rows = batch_start:batch_end;
    left_group = double(group_a(batch_rows));
    right_group = double(group_b(batch_rows));
    rows_in_batch = numel(batch_rows);

    small_timestamp_overlap = zeros(rows_in_batch, 1);
    matched_timestamps = zeros(rows_in_batch, 1);

    parfor (pair_in_batch = 1:rows_in_batch, number_of_workers)
        left_id = left_group(pair_in_batch);
        right_id = right_group(pair_in_batch);
        [overlap, ~, matches] = ...
            find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs( ...
            group_timestamps{left_id}, group_timestamps{right_id}, ...
            time_delta);
        small_timestamp_overlap(pair_in_batch) = 100 * overlap;
        matched_timestamps(pair_in_batch) = matches;
    end

    larger_timestamp_count = max(group_timestamp_count(left_group), ...
        group_timestamp_count(right_group));
    large_timestamp_overlap = ...
        100 * matched_timestamps ./ larger_timestamp_count;

    waveform_difference = group_waveforms(left_group, :) - ...
        group_waveforms(right_group, :);
    waveform_distance = sqrt(sum(waveform_difference .^ 2, 2));

    location_difference = group_location(left_group, :) - ...
        group_location(right_group, :);
    repwire_distance = sqrt(sum(location_difference .^ 2, 2));

    raw_features = single([small_timestamp_overlap, ...
        large_timestamp_overlap, matched_timestamps, waveform_distance, ...
        repwire_distance, group_cluster_count(left_group), ...
        group_cluster_count(right_group), ...
        group_timestamp_count(left_group), ...
        group_timestamp_count(right_group)]);
    normalized_features = ...
        (raw_features - normalization_mean) ./ normalization_std;
    scores = predict(final_net, normalized_features);
    merge_probability(batch_rows) = single(scores(:, 2));

    elapsed = toc(score_tic);
    rows_per_second = batch_end / max(elapsed, eps);
    remaining_minutes = (number_of_pairs - batch_end) / ...
        max(rows_per_second, eps) / 60;

    fprintf("scored %d / %d pairs (%.1f%%) | time %.1f min | " + ...
        "remaining %.1f min\n", batch_end, number_of_pairs, ...
        100 * batch_end / number_of_pairs, elapsed / 60, ...
        remaining_minutes);
end

%% Apply the same fixed probability and support rule

fprintf("applying probability %.2f and support %.2f...\n", ...
    probability_cutoff, support_cutoff);
grouping_tic = tic;

[nn_groups, safe_merges, candidate_links] = make_safe_groups( ...
    remove_conflicts_groups, group_a, group_b, merge_probability, ...
    probability_cutoff, support_cutoff);

fprintf("candidate links: %d\n", candidate_links);
fprintf("safe merges:     %d\n", safe_merges);
fprintf("final groups:    %d\n", numel(nn_groups));
fprintf("safe grouping took %.1f seconds\n", toc(grouping_tic));

%% Evaluate only after the groups are finished

[group_summary, unit_summary, grouping_summary] = summarize_result( ...
    nn_groups, max_overlap_unit, number_of_original_units, ...
    accuracy_cutoff, probability_cutoff, support_cutoff, ...
    number_of_clusters, number_of_starting_groups, candidate_links, ...
    safe_merges);

fprintf("\nFinal result at accuracy >= %.0f%%\n", accuracy_cutoff);
disp(grouping_summary);

result.accuracy_cutoff = accuracy_cutoff;
result.kept_row_indices = kept_row_indices;
result.remove_conflicts_groups = remove_conflicts_groups;
result.nn_groups = nn_groups;
result.group_summary = group_summary;
result.unit_summary = unit_summary;
result.grouping_summary = grouping_summary;
result.total_seconds = toc(cutoff_tic);
end

function groups = make_remove_conflicts_groups(merge_matrix)
    number_of_clusters = size(merge_matrix, 1);
    links = merge_matrix;
    links(1:number_of_clusters + 1:end) = false;
    is_conflict = false(number_of_clusters, 1);

    for cluster_id = 1:number_of_clusters
        neighbors = find(links(cluster_id, :));
        if numel(neighbors) >= 2
            neighbor_links = links(neighbors, neighbors);
            neighbor_links(1:numel(neighbors) + 1:end) = true;
            is_conflict(cluster_id) = ~all(neighbor_links, "all");
        end
    end

    conflict_clusters = find(is_conflict);
    clean_clusters = find(~is_conflict);
    clean_component = conncomp(graph(links(clean_clusters, clean_clusters)));
    number_of_clean_groups = max(clean_component, [], "all");
    groups = cell(number_of_clean_groups + numel(conflict_clusters), 1);

    for group_id = 1:number_of_clean_groups
        groups{group_id} = clean_clusters(clean_component == group_id);
    end
    for conflict_id = 1:numel(conflict_clusters)
        groups{number_of_clean_groups + conflict_id} = ...
            conflict_clusters(conflict_id);
    end

    if ~isequal(sort(vertcat(groups{:})), (1:number_of_clusters).')
        error("remove_conflicts lost or duplicated clusters.");
    end
end

function [groups, number_of_merges, number_of_candidates] = ...
        make_safe_groups(starting_groups, group_a, group_b, probability, ...
        probability_cutoff, support_cutoff)

    number_of_starting_groups = numel(starting_groups);
    probability_matrix = zeros(number_of_starting_groups, ...
        number_of_starting_groups, "single");
    matrix_rows = sub2ind(size(probability_matrix), ...
        double(group_a), double(group_b));
    probability_matrix(matrix_rows) = probability;
    probability_matrix = probability_matrix + probability_matrix.';
    probability_matrix(1:number_of_starting_groups + 1:end) = 1;

    candidate_rows = find(probability >= probability_cutoff);
    [~, order] = sort(probability(candidate_rows), "descend");
    candidate_rows = candidate_rows(order);
    number_of_candidates = numel(candidate_rows);

    component_for_group = (1:number_of_starting_groups).';
    component_members = num2cell((1:number_of_starting_groups).');
    component_is_alive = true(number_of_starting_groups, 1);
    number_of_merges = 0;

    for candidate_id = 1:number_of_candidates
        row = candidate_rows(candidate_id);
        left_component = component_for_group(group_a(row));
        right_component = component_for_group(group_b(row));

        if left_component == right_component
            continue
        end

        left_members = component_members{left_component};
        right_members = component_members{right_component};
        cross_probabilities = probability_matrix(left_members, right_members);
        cross_support = mean(cross_probabilities(:) >= probability_cutoff);

        if cross_support >= support_cutoff
            component_members{left_component} = ...
                [left_members(:); right_members(:)];
            component_members{right_component} = [];
            component_for_group(right_members) = left_component;
            component_is_alive(right_component) = false;
            number_of_merges = number_of_merges + 1;
        end
    end

    alive_components = find(component_is_alive);
    groups = cell(numel(alive_components), 1);
    for final_group_id = 1:numel(alive_components)
        old_group_ids = component_members{alive_components(final_group_id)};
        member_cells = starting_groups(old_group_ids);
        groups{final_group_id} = unique(vertcat(member_cells{:}));
    end
end

function [group_summary, unit_summary, summary] = summarize_result( ...
        groups, max_overlap_unit, number_of_original_units, ...
        accuracy_cutoff, probability_cutoff, support_cutoff, ...
        number_of_clusters, number_of_starting_groups, candidate_links, ...
        safe_merges)

    number_of_groups = numel(groups);
    group_id = (1:number_of_groups).';
    group_size = zeros(number_of_groups, 1);
    num_units = zeros(number_of_groups, 1);
    dominant_unit = nan(number_of_groups, 1);
    purity = zeros(number_of_groups, 1);
    is_pure = false(number_of_groups, 1);
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
        purity(current_group) = largest_count / numel(members);
        is_pure(current_group) = isscalar(unique_units_here);
        unit_list{current_group} = unique_units_here(:).';
        cluster_group_id(members) = current_group;
    end

    group_summary = table(group_id, group_size, num_units, dominant_unit, ...
        purity, is_pure, unit_list);

    retained_units = unique(max_overlap_unit);
    number_of_units = numel(retained_units);
    unit_id = retained_units(:);
    groups_with_unit = zeros(number_of_units, 1);
    clean_group_count = zeros(number_of_units, 1);
    perfectly_contained = false(number_of_units, 1);

    for unit_number = 1:number_of_units
        cluster_rows = find(max_overlap_unit == unit_id(unit_number));
        group_rows = unique(cluster_group_id(cluster_rows));
        groups_with_unit(unit_number) = numel(group_rows);
        clean_group_count(unit_number) = sum(is_pure(group_rows));
        perfectly_contained(unit_number) = ...
            isscalar(group_rows) && is_pure(group_rows);
    end

    unit_summary = table(unit_id, groups_with_unit, clean_group_count, ...
        perfectly_contained);

    pure_groups = sum(is_pure);
    contaminated_groups = sum(~is_pure);
    clusters_in_pure_groups = sum(group_size(is_pure));
    groups_per_unit_ratio = number_of_groups / number_of_units;
    fully_pure_group_percent = 100 * pure_groups / number_of_groups;
    mean_group_purity_percent = 100 * mean(purity);
    clusters_in_pure_percent = ...
        100 * clusters_in_pure_groups / number_of_clusters;
    unit_retention_percent = ...
        100 * number_of_units / number_of_original_units;
    fragmented_units = sum(groups_with_unit > 1);
    perfectly_contained_units = sum(perfectly_contained);
    units_with_clean_group = sum(clean_group_count > 0);
    largest_group_size = max(group_size);

    summary = table(accuracy_cutoff, probability_cutoff, support_cutoff, ...
        number_of_clusters, number_of_units, number_of_original_units, ...
        unit_retention_percent, number_of_starting_groups, number_of_groups, ...
        groups_per_unit_ratio, candidate_links, safe_merges, pure_groups, ...
        fully_pure_group_percent, mean_group_purity_percent, ...
        clusters_in_pure_percent, contaminated_groups, largest_group_size, ...
        fragmented_units, perfectly_contained_units, units_with_clean_group);
end
