%% Recording 6: test the frozen nine-feature NN at several accuracy filters
%
% The only setting changed in this experiment is the cluster accuracy filter.
% The council matrix rules, trained nine-feature network, normalization,
% probability cutoff, and support cutoff remain fixed.

clearvars -except ACCURACY_CUTOFFS BASE_ACCURACY_CUTOFF SWEEP_RESULT_NAME
clc

total_tic = tic;

if ~exist("ACCURACY_CUTOFFS", "var")
    ACCURACY_CUTOFFS = [5; 15; 25; 30; 35; 40; 45; 50; 55; 70];
end
if ~exist("BASE_ACCURACY_CUTOFF", "var")
    BASE_ACCURACY_CUTOFF = min(ACCURACY_CUTOFFS);
end
if ~exist("SWEEP_RESULT_NAME", "var")
    SWEEP_RESULT_NAME = "recording_6_selected_accuracy_cutoff_sweep";
end

NUMBER_OF_WORKERS = 6;

script_folder = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(script_folder)));

addpath(genpath(fullfile(repo_root, "clustering-master")));
addpath(genpath(fullfile(repo_root, "Utility_Functions")));
addpath(genpath(fullfile(repo_root, "Neural_Networks")));
cd(repo_root);





config = spikesort_config();

result_folder = fullfile(repo_root, "Default_Results_Dir", ...
    "recording_6_accuracy_sweep");
base_matrix_file = fullfile(result_folder, ...
    sprintf("recording_6_min170_accuracy%d_base_matrix.mat", ...
    BASE_ACCURACY_CUTOFF));
model_file = fullfile(repo_root, "Default_Results_Dir", ...
    "group_pair_nn_clear_experiment_result.mat");
completed_accuracy15_file = fullfile(repo_root, "Default_Results_Dir", ...
    "recording_6_new_pipeline", "recording_6_nn_regrouping_result.mat");
summary_file = fullfile(result_folder, ...
    SWEEP_RESULT_NAME + "_result.mat");
figure_file = fullfile(result_folder, ...
    SWEEP_RESULT_NAME + ".png");

if ~isfile(base_matrix_file)
    error("The completed %d percent base matrix was not found.", ...
        BASE_ACCURACY_CUTOFF);
end

if ~isfile(model_file)
    error("The saved nine-feature network was not found.");
end

%% Load the frozen model and the completed base matrix

fprintf("\nLoading the recording 6 base matrix and frozen NN...\n");
load_tic = tic;

base_result = load(base_matrix_file, "input_file", ...
    "base_row_indices", "merge_matrix", "MINIMUM_SPIKES", ...
    "BASE_ACCURACY_CUTOFF");
input_result = load(base_result.input_file, "data_to_save");
model_result = load(model_file, "final_net", "final_feature_mean", ...
    "final_feature_std", "feature_names", ...
    "selected_probability_cutoff", "selected_support_cutoff");

if ~isfield(input_result, "data_to_save") || ...
        ~istable(input_result.data_to_save)
    error("The recording 6 input table could not be loaded.");
end

expected_feature_names = [
    "small_timestamp_overlap"
    "large_timestamp_overlap"
    "matched_timestamps"
    "waveform_distance"
    "repwire_distance"
    "left_cluster_count"
    "right_cluster_count"
    "left_timestamp_count"
    "right_timestamp_count"
];

if ~isequal(string(model_result.feature_names(:)), expected_feature_names)
    error("The saved network does not use the expected nine features.");
end

if base_result.MINIMUM_SPIKES ~= 170 || ...
        base_result.BASE_ACCURACY_CUTOFF ~= BASE_ACCURACY_CUTOFF || ...
        any(ACCURACY_CUTOFFS < BASE_ACCURACY_CUTOFF)
    error("The base matrix does not match this accuracy sweep.");
end

bp = input_result.data_to_save;
base_row_indices = base_result.base_row_indices;
base_merge_matrix = logical(base_result.merge_matrix);
final_net = model_result.final_net;
feature_mean = model_result.final_feature_mean;
feature_std = model_result.final_feature_std;
probability_cutoff = double(model_result.selected_probability_cutoff);
support_cutoff = double(model_result.selected_support_cutoff);

fprintf("accuracy cutoffs:      %s percent\n", ...
    strjoin(string(ACCURACY_CUTOFFS.'), ", "));
fprintf("minimum spikes:        %d\n", base_result.MINIMUM_SPIKES);
fprintf("NN probability cutoff: %.2f\n", probability_cutoff);
fprintf("support cutoff:        %.2f\n", support_cutoff);
fprintf("base clusters:         %d\n", numel(base_row_indices));
fprintf("loading took %.1f seconds\n", toc(load_tic));

clear input_result model_result base_result

%% Start the workers once and test every accuracy cutoff

workers_for_parfor = 0;
if license("test", "Distrib_Computing_Toolbox")
    current_pool = gcp("nocreate");
    if isempty(current_pool)
        try
            current_pool = parpool("Processes", NUMBER_OF_WORKERS);
        catch pool_error
            fprintf("parallel pool failed: %s\n", pool_error.message);
        end
    end
    if ~isempty(current_pool)
        workers_for_parfor = min(NUMBER_OF_WORKERS, current_pool.NumWorkers);
    end
end

fprintf("using %d worker(s)\n", max(workers_for_parfor, 1));

accuracy_sweep_summary = table();
cutoff_result_files = strings(numel(ACCURACY_CUTOFFS), 1);

for cutoff_id = 1:numel(ACCURACY_CUTOFFS)
    accuracy_cutoff = ACCURACY_CUTOFFS(cutoff_id);
    cutoff_result_file = fullfile(result_folder, sprintf( ...
        "recording_6_accuracy_%02d_nn_result.mat", accuracy_cutoff));
    cutoff_result_files(cutoff_id) = string(cutoff_result_file);

    if isfile(cutoff_result_file)
        saved_result = load(cutoff_result_file, "grouping_summary", ...
            "source_base_matrix_file", "source_model_file");
        saved_result_matches = ...
            string(saved_result.source_base_matrix_file) == ...
                string(base_matrix_file) && ...
            string(saved_result.source_model_file) == string(model_file) && ...
            saved_result.grouping_summary.accuracy_cutoff == accuracy_cutoff;

        if ~saved_result_matches
            error("Existing cutoff result does not match: %s", ...
                cutoff_result_file);
        end

        fprintf("\naccuracy %.0f%% is already complete; loading it\n", ...
            accuracy_cutoff);
        accuracy_sweep_summary = [accuracy_sweep_summary; ...
            saved_result.grouping_summary]; %#ok<AGROW>
        continue
    end

    % The original recording 6 experiment already completed this exact
    % cutoff with this network and grouping policy, so reuse it.
    if accuracy_cutoff == 15 && isfile(completed_accuracy15_file)
        old_result = load(completed_accuracy15_file, "nn_groups", ...
            "nn_group_summary", "nn_unit_summary", "nn_grouping_summary", ...
            "group_result", "probability_cutoff", "support_cutoff", ...
            "candidate_rows", "safe_merges", "source_model_file");

        if old_result.probability_cutoff ~= probability_cutoff || ...
                old_result.support_cutoff ~= support_cutoff || ...
                string(old_result.source_model_file) ~= string(model_file)
            error("The completed 15 percent result used different settings.");
        end

        old_summary = old_result.nn_grouping_summary;
        number_of_original_units = numel(unique(bp{:, "Max_Overlap_Unit"}));
        number_of_starting_groups = ...
            numel(old_result.group_result.remove_conflicts_groups);
        grouping_summary = table(accuracy_cutoff, probability_cutoff, ...
            support_cutoff, old_summary.num_clusters, ...
            old_summary.num_unique_units, number_of_original_units, ...
            100 * old_summary.num_unique_units / number_of_original_units, ...
            number_of_starting_groups, old_summary.num_groups, ...
            old_summary.groups_per_unit_ratio, numel(old_result.candidate_rows), ...
            old_result.safe_merges, old_summary.pure_groups, ...
            old_summary.fully_pure_group_percent, ...
            old_summary.mean_group_purity_percent, ...
            old_summary.clusters_in_pure_percent, ...
            old_summary.contaminated_groups, old_summary.largest_group_size, ...
            old_summary.fragmented_units, ...
            old_summary.perfectly_contained_units, ...
            old_summary.units_with_clean_group, ...
            'VariableNames', {'accuracy_cutoff', 'probability_cutoff', ...
            'support_cutoff', 'number_of_clusters', 'number_of_units', ...
            'number_of_original_units', 'unit_retention_percent', ...
            'number_of_starting_groups', 'number_of_groups', ...
            'groups_per_unit_ratio', 'candidate_links', 'safe_merges', ...
            'pure_groups', 'fully_pure_group_percent', ...
            'mean_group_purity_percent', 'clusters_in_pure_percent', ...
            'contaminated_groups', 'largest_group_size', ...
            'fragmented_units', 'perfectly_contained_units', ...
            'units_with_clean_group'});

        kept_row_indices = old_result.group_result.kept_row_indices;
        remove_conflicts_groups = ...
            old_result.group_result.remove_conflicts_groups;
        nn_groups = old_result.nn_groups;
        group_summary = old_result.nn_group_summary;
        unit_summary = old_result.nn_unit_summary;
        cutoff_seconds = 0;
        source_base_matrix_file = base_matrix_file;
        source_model_file = model_file;

        save(cutoff_result_file, "accuracy_cutoff", "kept_row_indices", ...
            "remove_conflicts_groups", "nn_groups", "group_summary", ...
            "unit_summary", "grouping_summary", "probability_cutoff", ...
            "support_cutoff", "source_base_matrix_file", ...
            "source_model_file", "cutoff_seconds", "-v7.3");

        fprintf("\naccuracy 15%% reused the completed old-NN result\n");
        accuracy_sweep_summary = [accuracy_sweep_summary; ...
            grouping_summary]; %#ok<AGROW>
        continue
    end

    cutoff_result = run_one_accuracy_cutoff(accuracy_cutoff, bp, ...
        base_row_indices, base_merge_matrix, final_net, feature_mean, ...
        feature_std, probability_cutoff, support_cutoff, config, ...
        workers_for_parfor);

    kept_row_indices = cutoff_result.kept_row_indices;
    remove_conflicts_groups = cutoff_result.remove_conflicts_groups;
    nn_groups = cutoff_result.nn_groups;
    group_summary = cutoff_result.group_summary;
    unit_summary = cutoff_result.unit_summary;
    grouping_summary = cutoff_result.grouping_summary;
    cutoff_seconds = cutoff_result.total_seconds;
    source_base_matrix_file = base_matrix_file;
    source_model_file = model_file;

    save(cutoff_result_file, "accuracy_cutoff", "kept_row_indices", ...
        "remove_conflicts_groups", "nn_groups", "group_summary", ...
        "unit_summary", "grouping_summary", "probability_cutoff", ...
        "support_cutoff", "source_base_matrix_file", ...
        "source_model_file", "cutoff_seconds", "-v7.3");

    fprintf("saved cutoff result to:\n%s\n", cutoff_result_file);
    accuracy_sweep_summary = [accuracy_sweep_summary; ...
        grouping_summary]; %#ok<AGROW>
end

%% Print, plot, and save the complete comparison

accuracy_sweep_summary = sortrows(accuracy_sweep_summary, ...
    "accuracy_cutoff");

fprintf("\n============================================================\n");
fprintf("Recording 6 accuracy-cutoff comparison\n");
disp(accuracy_sweep_summary);

figure("Color", "white", "Position", [80 100 1400 440]);
tiledlayout(1, 3, "TileSpacing", "compact", "Padding", "compact");

nexttile
plot(accuracy_sweep_summary.accuracy_cutoff, ...
    accuracy_sweep_summary.groups_per_unit_ratio, "o-", ...
    "LineWidth", 1.8, "MarkerSize", 7);
yline(1, "--", "ideal ratio = 1", "LineWidth", 1.2);
xlabel("Minimum cluster accuracy (%)");
ylabel("Final groups / retained units");
title("Fragmentation");
grid on

nexttile
plot(accuracy_sweep_summary.accuracy_cutoff, ...
    accuracy_sweep_summary.fully_pure_group_percent, "o-", ...
    "LineWidth", 1.8, "MarkerSize", 7);
xlabel("Minimum cluster accuracy (%)");
ylabel("Fully pure groups (%)");
title("Group purity");
ylim([0 100]);
grid on

nexttile
plot(accuracy_sweep_summary.accuracy_cutoff, ...
    accuracy_sweep_summary.unit_retention_percent, "o-", ...
    "LineWidth", 1.8, "MarkerSize", 7);
xlabel("Minimum cluster accuracy (%)");
ylabel("Original units retained (%)");
title("Unit retention");
ylim([0 100]);
grid on

exportgraphics(gcf, figure_file, "Resolution", 200);

total_seconds = toc(total_tic);
save(summary_file, "accuracy_sweep_summary", "ACCURACY_CUTOFFS", ...
    "probability_cutoff", "support_cutoff", "cutoff_result_files", ...
    "base_matrix_file", "model_file", "figure_file", ...
    "total_seconds", "-v7.3");

fprintf("\nsaved complete sweep to:\n%s\n", summary_file);
fprintf("saved figure to:\n%s\n", figure_file);
fprintf("total sweep time: %.1f minutes\n", total_seconds / 60);
%
