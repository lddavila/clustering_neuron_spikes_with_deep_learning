function result = build_full_ensemble_matrix(bp, valid_row_indices, ...
        input_file, result_file, checkpoint_file, repo_root, ...
        worker_count, rebuild_matrix)
%BUILD_FULL_ENSEMBLE_MATRIX Compare every structurally valid cluster pair.
%
% This is the expensive part of the pipeline. The result is independent of
% the spike-count and accuracy filters, so the same matrix can be reused for
% every cutoff and for later filter experiments.

settings.time_delta = 0.0002;
settings.timestamp_overlap_cutoff = 5;
settings.waveform_distance_cutoff = 220;
settings.ensemble_probability_cutoff = 0.95;
settings.batch_size = 25000;

source_info = dir(input_file);
source_bytes = source_info.bytes;
source_modified = source_info.datenum;
number_of_clusters = numel(valid_row_indices);
number_of_pairs = number_of_clusters * (number_of_clusters - 1) / 2;

if rebuild_matrix
    if isfile(result_file)
        delete(result_file);
    end
    if isfile(checkpoint_file)
        delete(checkpoint_file);
    end
end

if isfile(result_file)
    saved = load(result_file, "input_file", "source_bytes", ...
        "source_modified", "valid_row_indices", "settings", ...
        "merge_matrix", "matrix_complete");
    result_matches = saved.matrix_complete && ...
        string(saved.input_file) == string(input_file) && ...
        saved.source_bytes == source_bytes && ...
        saved.source_modified == source_modified && ...
        isequal(saved.valid_row_indices, valid_row_indices) && ...
        isequal(saved.settings, settings);

    if result_matches
        fprintf("\nThe complete ensemble matrix already exists.\n");
        result = saved;
        return
    end
    error("The saved complete matrix belongs to a different input or setup. " + ...
        "Run again with RebuildMatrix=true to replace it.");
end

fprintf("\nPreparing the five-network ensemble...\n");
ensemble_files = struct2table(dir(fullfile(repo_root, "Neural_Networks", ...
    "**", "simplest_group_or_dont_rec_*.mat")));

if height(ensemble_files) ~= 5
    error("Expected five ensemble networks, but found %d.", ...
        height(ensemble_files));
end

ensemble_files.folder = string(ensemble_files.folder);
ensemble_files.name = string(ensemble_files.name);
split_names = split(erase(ensemble_files.name, ".mat"), "_");
ensemble_files.recording_number = str2double(split_names(:, end));
ensemble_files = sortrows(ensemble_files, "recording_number");

ensemble_nets = cell(5, 1);
for net_id = 1:5
    ensemble_nets{net_id} = importdata(fullfile( ...
        ensemble_files.folder(net_id), ensemble_files.name(net_id)));
    fprintf("  %s\n", ensemble_files.name(net_id));
end

bp_valid = bp(valid_row_indices, :);
waveforms = cell2mat(bp_valid{:, "mean_waveform_rep_wire_1"});
representative_channel = get_representative_channels(bp_valid);
probe_locations = get_probe_xy();
wire_locations = probe_locations(representative_channel, :);

timestamp_column = bp_valid{:, "timestamps"};
timestamps = cell(number_of_clusters, 1);
for cluster_id = 1:number_of_clusters
    cluster_timestamps = timestamp_column{cluster_id};
    if iscell(cluster_timestamps) && isscalar(cluster_timestamps)
        cluster_timestamps = cluster_timestamps{1};
    end
    timestamps{cluster_id} = cluster_timestamps(:);
end

ensemble_network_names = ensemble_files.name;

if isfile(checkpoint_file)
    checkpoint = load(checkpoint_file, "input_file", "source_bytes", ...
        "source_modified", "valid_row_indices", "settings", ...
        "number_of_clusters", "number_of_pairs", ...
        "ensemble_network_names", "last_completed_pair");
    checkpoint_matches = string(checkpoint.input_file) == string(input_file) && ...
        checkpoint.source_bytes == source_bytes && ...
        checkpoint.source_modified == source_modified && ...
        isequal(checkpoint.valid_row_indices, valid_row_indices) && ...
        isequal(checkpoint.settings, settings) && ...
        checkpoint.number_of_clusters == number_of_clusters && ...
        checkpoint.number_of_pairs == number_of_pairs && ...
        isequal(string(checkpoint.ensemble_network_names), ...
        string(ensemble_network_names));

    if ~checkpoint_matches
        error("The matrix checkpoint belongs to a different run. " + ...
            "Use RebuildMatrix=true to replace it.");
    end
    last_completed_pair = double(checkpoint.last_completed_pair);
    fprintf("resuming after pair %d / %d\n", ...
        last_completed_pair, number_of_pairs);
else
    last_completed_pair = uint64(0);
    matrix_complete = false;
    save(checkpoint_file, "input_file", "source_bytes", ...
        "source_modified", "valid_row_indices", "settings", ...
        "number_of_clusters", "number_of_pairs", ...
        "ensemble_network_names", "last_completed_pair", ...
        "matrix_complete", "-v7.3");

    checkpoint_data = matfile(checkpoint_file, "Writable", true);
    if number_of_pairs > 0
        checkpoint_data.merge_decision(number_of_pairs, 1) = false;
    else
        checkpoint_data.merge_decision = false(0, 1);
    end
end

checkpoint_data = matfile(checkpoint_file, "Writable", true);
first_pair_this_run = double(last_completed_pair) + 1;
matrix_tic = tic;

fprintf("\nBuilding the complete %d x %d ensemble matrix...\n", ...
    number_of_clusters, number_of_clusters);
fprintf("unique cluster pairs: %d\n", number_of_pairs);

for batch_start = first_pair_this_run:settings.batch_size:number_of_pairs
    batch_end = min(batch_start + settings.batch_size - 1, number_of_pairs);
    pair_ids = batch_start:batch_end;
    [left_cluster, right_cluster] = pair_ids_to_group_ids(pair_ids);
    batch_decision = false(numel(pair_ids), 1);

    if worker_count > 0
        parfor (pair_in_batch = 1:numel(pair_ids), worker_count)
            batch_decision(pair_in_batch) = check_ensemble_merge( ...
                left_cluster(pair_in_batch), right_cluster(pair_in_batch), ...
                waveforms, timestamps, wire_locations, ensemble_nets, settings);
        end
    else
        for pair_in_batch = 1:numel(pair_ids)
            batch_decision(pair_in_batch) = check_ensemble_merge( ...
                left_cluster(pair_in_batch), right_cluster(pair_in_batch), ...
                waveforms, timestamps, wire_locations, ensemble_nets, settings);
        end
    end

    checkpoint_data.merge_decision(pair_ids, 1) = batch_decision;
    checkpoint_data.last_completed_pair = uint64(batch_end);

    completed_this_run = batch_end - first_pair_this_run + 1;
    elapsed = toc(matrix_tic);
    pairs_per_second = completed_this_run / max(elapsed, eps);
    remaining_minutes = (number_of_pairs - batch_end) / ...
        max(pairs_per_second, eps) / 60;

    fprintf("checked %d / %d pairs (%.1f%%) | time %.1f min | " + ...
        "remaining %.1f min\n", batch_end, number_of_pairs, ...
        100 * batch_end / max(number_of_pairs, 1), elapsed / 60, ...
        remaining_minutes);
end

merge_matrix = false(number_of_clusters, number_of_clusters);
merge_matrix(1:number_of_clusters + 1:end) = true;

next_pair = 1;
for right_cluster = 2:number_of_clusters
    pair_rows = next_pair:(next_pair + right_cluster - 2);
    decisions = checkpoint_data.merge_decision(pair_rows, 1);
    merge_matrix(1:right_cluster - 1, right_cluster) = decisions;
    merge_matrix(right_cluster, 1:right_cluster - 1) = decisions.';
    next_pair = pair_rows(end) + 1;
end

accepted_merge_links = nnz(triu(merge_matrix, 1));
matrix_seconds = toc(matrix_tic);
matrix_complete = true;

save(result_file, "input_file", "source_bytes", "source_modified", ...
    "valid_row_indices", "settings", "number_of_clusters", ...
    "number_of_pairs", "ensemble_network_names", "merge_matrix", ...
    "accepted_merge_links", "matrix_seconds", "matrix_complete", "-v7.3");

checkpoint_data.matrix_complete = true;
fprintf("complete matrix saved to:\n%s\n", result_file);
fprintf("accepted merge links: %d\n", accepted_merge_links);
fprintf("matrix time this run: %.1f minutes\n", matrix_seconds / 60);

result = load(result_file);
end
