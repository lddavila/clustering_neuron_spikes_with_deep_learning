function [groups, number_of_merges, number_of_candidates] = ...
        merge_groups_with_support(starting_groups, probability, ...
        probability_cutoff, support_cutoff)
%MERGE_GROUPS_WITH_SUPPORT Merge starting groups using trained-NN evidence.
%
% Candidate pairs are checked from highest to lowest merge probability.
% When two growing groups are considered, support is the fraction of all
% cross-comparisons that meet the same probability cutoff.

number_of_starting_groups = numel(starting_groups);
expected_pairs = number_of_starting_groups * ...
    (number_of_starting_groups - 1) / 2;
probability = single(probability(:));

if numel(probability) ~= expected_pairs
    error("The probability vector does not match the starting groups.");
end

if number_of_starting_groups <= 1
    groups = starting_groups;
    number_of_merges = 0;
    number_of_candidates = 0;
    return
end

probability_matrix = zeros(number_of_starting_groups, ...
    number_of_starting_groups, "single");
next_pair = 1;
for right_group = 2:number_of_starting_groups
    pair_rows = next_pair:(next_pair + right_group - 2);
    values = probability(pair_rows);
    probability_matrix(1:right_group - 1, right_group) = values;
    probability_matrix(right_group, 1:right_group - 1) = values.';
    next_pair = pair_rows(end) + 1;
end
probability_matrix(1:number_of_starting_groups + 1:end) = 1;

candidate_pair_ids = find(probability >= probability_cutoff);
[~, candidate_order] = sort(probability(candidate_pair_ids), "descend");
candidate_pair_ids = candidate_pair_ids(candidate_order);
number_of_candidates = numel(candidate_pair_ids);
[candidate_left, candidate_right] = ...
    pair_ids_to_group_ids(candidate_pair_ids);

component_for_group = (1:number_of_starting_groups).';
component_members = num2cell((1:number_of_starting_groups).');
component_is_alive = true(number_of_starting_groups, 1);
number_of_merges = 0;

for candidate_id = 1:number_of_candidates
    left_component = component_for_group(candidate_left(candidate_id));
    right_component = component_for_group(candidate_right(candidate_id));

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

fprintf("candidate links: %d\n", number_of_candidates);
fprintf("safe merges:     %d\n", number_of_merges);
fprintf("final groups:    %d\n", numel(groups));
end
