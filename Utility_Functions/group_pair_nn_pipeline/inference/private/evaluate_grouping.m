function [group_summary, unit_summary, summary] = evaluate_grouping( ...
        groups, max_overlap_unit, number_of_original_units, ...
        accuracy_cutoff, probability_cutoff, support_cutoff, ...
        number_of_clusters, number_of_starting_groups, candidate_links, ...
        safe_merges)
%EVALUATE_GROUPING Summarize one final grouping result.
%
% Ground-truth columns are only read here, after grouping is complete. When
% ground truth is unavailable, the structural counts are still returned and
% purity fields are left as NaN.

number_of_groups = numel(groups);
group_id = (1:number_of_groups).';
group_size = cellfun(@numel, groups);
largest_group_size = max(group_size);

has_ground_truth = ~isempty(max_overlap_unit);
if ~has_ground_truth
    num_units = nan(number_of_groups, 1);
    dominant_unit = nan(number_of_groups, 1);
    purity = nan(number_of_groups, 1);
    is_pure = nan(number_of_groups, 1);
    unit_list = cell(number_of_groups, 1);
    group_summary = table(group_id, group_size, num_units, ...
        dominant_unit, purity, is_pure, unit_list);
    unit_summary = table();

    number_of_units = NaN;
    unit_retention_percent = NaN;
    pure_groups = NaN;
    fully_pure_group_percent = NaN;
    mean_group_purity_percent = NaN;
    clusters_in_pure_percent = NaN;
    contaminated_groups = NaN;
    fragmented_units = NaN;
    perfectly_contained_units = NaN;
    units_with_clean_group = NaN;
    groups_per_unit_ratio = NaN;
else
    max_overlap_unit = max_overlap_unit(:);
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

        for unit_id = 1:numel(unique_units_here)
            unit_counts(unit_id) = sum(units_here == unique_units_here(unit_id));
        end

        [largest_count, largest_position] = max(unit_counts);
        num_units(current_group) = numel(unique_units_here);
        dominant_unit(current_group) = unique_units_here(largest_position);
        purity(current_group) = largest_count / numel(members);
        is_pure(current_group) = isscalar(unique_units_here);
        unit_list{current_group} = unique_units_here(:).';
        cluster_group_id(members) = current_group;
    end

    group_summary = table(group_id, group_size, num_units, ...
        dominant_unit, purity, is_pure, unit_list);

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
    fully_pure_group_percent = 100 * pure_groups / number_of_groups;
    mean_group_purity_percent = 100 * mean(purity);
    clusters_in_pure_percent = ...
        100 * sum(group_size(is_pure)) / number_of_clusters;
    unit_retention_percent = ...
        100 * number_of_units / number_of_original_units;
    fragmented_units = sum(groups_with_unit > 1);
    perfectly_contained_units = sum(perfectly_contained);
    units_with_clean_group = sum(clean_group_count > 0);
    groups_per_unit_ratio = number_of_groups / number_of_units;
end

summary = table(accuracy_cutoff, probability_cutoff, support_cutoff, ...
    number_of_clusters, number_of_units, number_of_original_units, ...
    unit_retention_percent, number_of_starting_groups, number_of_groups, ...
    groups_per_unit_ratio, candidate_links, safe_merges, pure_groups, ...
    fully_pure_group_percent, mean_group_purity_percent, ...
    clusters_in_pure_percent, contaminated_groups, largest_group_size, ...
    fragmented_units, perfectly_contained_units, units_with_clean_group, ...
    'VariableNames', {'accuracy_cutoff', 'probability_cutoff', ...
    'support_cutoff', 'number_of_clusters', 'number_of_units', ...
    'number_of_original_units', 'unit_retention_percent', ...
    'number_of_starting_groups', 'number_of_groups', ...
    'groups_per_unit_ratio', 'candidate_links', 'safe_merges', ...
    'pure_groups', 'fully_pure_group_percent', ...
    'mean_group_purity_percent', 'clusters_in_pure_percent', ...
    'contaminated_groups', 'largest_group_size', 'fragmented_units', ...
    'perfectly_contained_units', 'units_with_clean_group'});
end
