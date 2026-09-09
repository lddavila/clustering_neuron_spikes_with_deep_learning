%% Simple cluster filter for recording 6
%
% Keep clusters with at least 170 spikes and at least 15 percent accuracy.
% Accuracy is available here because recording 6 is simulated. This part
% cannot be used on real data because real recordings have no answer key.

clearvars
clc

total_tic = tic;

MINIMUM_SPIKES = 170;
MINIMUM_ACCURACY = 15;

script_folder = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(script_folder)));
INPUT_FILE = fullfile(repo_root, "Data", ...
    "6_600Neuron300SecondRecordingWithLevel6Noise", ...
    "blind_pass_table.mat");
result_folder = fullfile(repo_root, "Default_Results_Dir", ...
    "recording_6_new_pipeline");
result_file = fullfile(result_folder, ...
    "recording_6_min170_accuracy15_filter.mat");

if ~isfolder(result_folder)
    mkdir(result_folder);
end

fprintf("\nRecording 6 simple cluster filter\n");
fprintf("input: %s\n\n", INPUT_FILE);

%% Load the blind-pass table

fprintf("Loading the blind-pass table...\n");
load_tic = tic;

loaded_file = load(INPUT_FILE, "data_to_save");
if ~isfield(loaded_file, "data_to_save") || ~istable(loaded_file.data_to_save)
    error("The MAT file does not contain the expected data_to_save table.");
end

bp = loaded_file.data_to_save;
clear loaded_file

column_names = string(bp.Properties.VariableNames);
if ~ismember("timestamps", column_names) || ~ismember("accuracy", column_names)
    error("The table must contain timestamps and accuracy.");
end

number_of_clusters = height(bp);
fprintf("clusters before filtering: %d\n", number_of_clusters);
fprintf("loading took %.1f seconds\n", toc(load_tic));

%% Count the spikes in each cluster

fprintf("\nCounting spikes...\n");
filter_tic = tic;

timestamp_column = bp{:, "timestamps"};
spike_count = zeros(number_of_clusters, 1);

for cluster_id = 1:number_of_clusters
    timestamps = timestamp_column{cluster_id};
    if iscell(timestamps)
        timestamps = timestamps{1};
    end

    spike_count(cluster_id) = numel(timestamps);
end

cluster_accuracy = bp{:, "accuracy"};

enough_spikes = spike_count >= MINIMUM_SPIKES;
enough_accuracy = cluster_accuracy >= MINIMUM_ACCURACY;
keep_cluster = enough_spikes & enough_accuracy;

kept_row_indices = find(keep_cluster);
removed_row_indices = find(~keep_cluster);
filter_seconds = toc(filter_tic);

fprintf("\n--- Filter Result ---\n");
fprintf("minimum spikes:                      %d\n", MINIMUM_SPIKES);
fprintf("minimum accuracy:                    %.1f%%\n", MINIMUM_ACCURACY);
fprintf("clusters with fewer than %d spikes: %d\n", ...
    MINIMUM_SPIKES, sum(~enough_spikes));
fprintf("clusters below %.1f%% accuracy:       %d\n", ...
    MINIMUM_ACCURACY, sum(~enough_accuracy));
fprintf("clusters removed in total:           %d\n", numel(removed_row_indices));
fprintf("clusters kept:                       %d (%.1f%%)\n", ...
    numel(kept_row_indices), 100 * mean(keep_cluster));
fprintf("median accuracy before filtering:    %.2f%%\n", ...
    median(cluster_accuracy));
fprintf("median accuracy after filtering:     %.2f%%\n", ...
    median(cluster_accuracy(keep_cluster)));
fprintf("filtering took %.1f seconds\n", filter_seconds);

%% Check how many simulated units remain

raw_unique_units = NaN;
filtered_unique_units = NaN;
units_removed_completely = [];

if ismember("Max_Overlap_Unit", column_names)
    all_units = bp{:, "Max_Overlap_Unit"};
    raw_unit_list = unique(all_units);
    filtered_unit_list = unique(all_units(keep_cluster));

    raw_unique_units = numel(raw_unit_list);
    filtered_unique_units = numel(filtered_unit_list);
    units_removed_completely = setdiff(raw_unit_list, filtered_unit_list);

    fprintf("\n--- Unit Check ---\n");
    fprintf("unique units before filtering:       %d\n", raw_unique_units);
    fprintf("unique units after filtering:        %d\n", filtered_unique_units);
    fprintf("units removed completely:            %d\n", ...
        numel(units_removed_completely));
end

filter_summary = table(number_of_clusters, numel(kept_row_indices), ...
    numel(removed_row_indices), 100 * mean(keep_cluster), ...
    sum(~enough_spikes), sum(~enough_accuracy), ...
    raw_unique_units, filtered_unique_units, ...
    'VariableNames', {'clusters_before', 'clusters_kept', ...
    'clusters_removed', 'cluster_retention_percent', ...
    'failed_spike_count', 'failed_accuracy', ...
    'units_before', 'units_after'});

save(result_file, "kept_row_indices", "removed_row_indices", ...
    "spike_count", "cluster_accuracy", "filter_summary", ...
    "units_removed_completely", "MINIMUM_SPIKES", ...
    "MINIMUM_ACCURACY", "filter_seconds");

fprintf("\nsaved filter result to:\n%s\n", result_file);
fprintf("total script time: %.1f seconds\n", toc(total_tic));
