function merge_probability = calculate_group_pair_probabilities( ...
        bp_filtered, starting_groups, model, probability_file, ...
        kept_row_indices, worker_count)
%CALCULATE_GROUP_PAIR_PROBABILITIES Score every remove_conflicts group pair.
%
% Features are built in batches, normalized with the values saved from
% training, and immediately passed to the trained neural network. Only the
% resulting merge probabilities are kept on disk.

number_of_clusters = height(bp_filtered);
number_of_groups = numel(starting_groups);
number_of_pairs = number_of_groups * (number_of_groups - 1) / 2;
feature_names = string(model.feature_names(:));
starting_group_sizes = cellfun(@numel, starting_groups);
time_delta = 0.0002;
batch_size = 100000;

if isfile(probability_file)
    saved = load(probability_file, "number_of_groups", "number_of_pairs", ...
        "feature_names", "starting_group_sizes", "kept_row_indices", ...
        "last_completed_pair", "scoring_complete");
    probability_matches = saved.number_of_groups == number_of_groups && ...
        saved.number_of_pairs == number_of_pairs && ...
        isequal(string(saved.feature_names(:)), feature_names) && ...
        isequal(saved.starting_group_sizes, starting_group_sizes) && ...
        isequal(saved.kept_row_indices, kept_row_indices);

    if ~probability_matches
        error("The saved probability file belongs to a different cutoff run:\n%s", ...
            probability_file);
    end

    if saved.scoring_complete
        fprintf("pair probabilities already exist; loading them\n");
        probability_data = matfile(probability_file);
        merge_probability = probability_data.merge_probability;
        return
    end
    last_completed_pair = double(saved.last_completed_pair);
    fprintf("resuming probability scoring after pair %d / %d\n", ...
        last_completed_pair, number_of_pairs);
else
    last_completed_pair = uint64(0);
    scoring_complete = false;
    save(probability_file, "number_of_groups", "number_of_pairs", ...
        "feature_names", "starting_group_sizes", "kept_row_indices", ...
        "last_completed_pair", "scoring_complete", "-v7.3");
    probability_data = matfile(probability_file, "Writable", true);
    if number_of_pairs > 0
        probability_data.merge_probability(number_of_pairs, 1) = single(0);
    else
        probability_data.merge_probability = zeros(0, 1, "single");
    end
end

timestamp_column = bp_filtered{:, "timestamps"};
cluster_timestamps = cell(number_of_clusters, 1);
for cluster_id = 1:number_of_clusters
    timestamps = timestamp_column{cluster_id};
    if iscell(timestamps) && isscalar(timestamps)
        timestamps = timestamps{1};
    end
    cluster_timestamps{cluster_id} = timestamps(:);
end

group_timestamps = cell(number_of_groups, 1);
group_cluster_count = zeros(number_of_groups, 1);
group_timestamp_count = zeros(number_of_groups, 1);

for group_id = 1:number_of_groups
    members = starting_groups{group_id};
    timestamps = unique(sort(vertcat(cluster_timestamps{members})));
    group_timestamps{group_id} = timestamps;
    group_cluster_count(group_id) = numel(members);
    group_timestamp_count(group_id) = numel(timestamps);
end

cluster_waveforms = cell2mat( ...
    bp_filtered{:, "mean_waveform_rep_wire_1"});
group_waveforms = zeros(number_of_groups, size(cluster_waveforms, 2));
for group_id = 1:number_of_groups
    group_waveforms(group_id, :) = mean( ...
        cluster_waveforms(starting_groups{group_id}, :), 1);
end

representative_channel = get_representative_channels(bp_filtered);
probe_locations = get_probe_xy();
cluster_location = probe_locations(representative_channel, :);
group_location = zeros(number_of_groups, 2);
for group_id = 1:number_of_groups
    group_location(group_id, :) = mean( ...
        cluster_location(starting_groups{group_id}, :), 1);
end

probability_data = matfile(probability_file, "Writable", true);
normalization_mean = single(model.feature_mean(:).');
normalization_std = single(model.feature_std(:).');
first_pair_this_run = double(last_completed_pair) + 1;
score_tic = tic;

fprintf("scoring %d group pairs with the trained NN...\n", number_of_pairs);

for batch_start = first_pair_this_run:batch_size:number_of_pairs
    batch_end = min(batch_start + batch_size - 1, number_of_pairs);
    batch_rows = batch_start:batch_end;
    [left_group, right_group] = pair_ids_to_group_ids(batch_rows);
    rows_in_batch = numel(batch_rows);

    small_timestamp_overlap = zeros(rows_in_batch, 1);
    matched_timestamps = zeros(rows_in_batch, 1);

    if worker_count > 0
        parfor (pair_in_batch = 1:rows_in_batch, worker_count)
            left_id = left_group(pair_in_batch);
            right_id = right_group(pair_in_batch);
            [overlap, ~, matches] = ...
                find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs( ...
                group_timestamps{left_id}, group_timestamps{right_id}, ...
                time_delta);
            small_timestamp_overlap(pair_in_batch) = 100 * overlap;
            matched_timestamps(pair_in_batch) = matches;
        end
    else
        for pair_in_batch = 1:rows_in_batch
            left_id = left_group(pair_in_batch);
            right_id = right_group(pair_in_batch);
            [overlap, ~, matches] = ...
                find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs( ...
                group_timestamps{left_id}, group_timestamps{right_id}, ...
                time_delta);
            small_timestamp_overlap(pair_in_batch) = 100 * overlap;
            matched_timestamps(pair_in_batch) = matches;
        end
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

    raw_features = single([ ...
        small_timestamp_overlap, ...
        large_timestamp_overlap, ...
        matched_timestamps, ...
        waveform_distance, ...
        repwire_distance, ...
        group_cluster_count(left_group), ...
        group_cluster_count(right_group), ...
        group_timestamp_count(left_group), ...
        group_timestamp_count(right_group)]);

    normalized_features = ...
        (raw_features - normalization_mean) ./ normalization_std;
    scores = predict(model.final_net, normalized_features);
    probability_data.merge_probability(batch_rows, 1) = single(scores(:, 2));
    probability_data.last_completed_pair = uint64(batch_end);

    completed_this_run = batch_end - first_pair_this_run + 1;
    elapsed = toc(score_tic);
    rows_per_second = completed_this_run / max(elapsed, eps);
    remaining_minutes = (number_of_pairs - batch_end) / ...
        max(rows_per_second, eps) / 60;

    fprintf("scored %d / %d pairs (%.1f%%) | time %.1f min | " + ...
        "remaining %.1f min\n", batch_end, number_of_pairs, ...
        100 * batch_end / max(number_of_pairs, 1), elapsed / 60, ...
        remaining_minutes);
end

probability_data.scoring_complete = true;
probability_data.total_scoring_seconds = toc(score_tic);
merge_probability = probability_data.merge_probability;
end
