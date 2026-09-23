function [left_id, right_id] = pair_ids_to_group_ids(pair_id)
%PAIR_IDS_TO_GROUP_IDS Convert saved pair positions into two group numbers.
%
% Pairs are ordered as (1,2), (1,3), (2,3), (1,4), (2,4), (3,4), and so on.
% This keeps the pair ordering reproducible without saving two large columns
% of group numbers beside every probability vector.

pair_id = double(pair_id(:));
right_id = ceil((1 + sqrt(1 + 8 * pair_id)) / 2);
previous_pairs = (right_id - 1) .* (right_id - 2) / 2;
left_id = pair_id - previous_pairs;
end
