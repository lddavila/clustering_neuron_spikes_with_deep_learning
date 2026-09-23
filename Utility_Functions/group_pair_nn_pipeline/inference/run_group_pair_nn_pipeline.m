function accuracy_sweep_summary = run_group_pair_nn_pipeline(bp_table_file, options)
%RUN_GROUP_PAIR_NN_PIPELINE Apply the trained group-pair NN to one recording.
%
% This pipeline starts from a blind-pass table. It first builds one complete
% ensemble merge matrix for every structurally valid cluster. That matrix is
% reused for every cluster-accuracy cutoff, so the five ensemble networks are
% only run once.
%
% For each cutoff, the selected part of the matrix is grouped with the
% remove_conflicts strategy. The nine group-pair features are then calculated,
% normalized with the recording 10 training values, and scored by the trained
% neural network. The saved probability and support cutoffs make the final
% groups.
%
% Accuracy and Max_Overlap_Unit are only used for filtering and evaluation.
% They are never given to either neural-network stage. If those columns are
% absent, the pipeline still makes groups, but it cannot report ground-truth
% purity or the groups-per-unit ratio.

arguments
    bp_table_file (1, 1) string
    options.MinimumSpikes (1, 1) double {mustBeNonnegative} = 170
    options.AccuracyCutoffs double = 0:5:100
    options.NumberOfWorkers (1, 1) double {mustBeInteger, mustBeNonnegative} = 6
    options.OutputFolder (1, 1) string = ""
    options.ModelFile (1, 1) string = ""
    options.ProbabilityCutoff double = []
    options.SupportCutoff double = []
    options.RebuildMatrix (1, 1) logical = false
end

total_tic = tic;
script_folder = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(script_folder)));

addpath(genpath(fullfile(repo_root, "clustering-master")), "-begin");
addpath(genpath(fullfile(repo_root, "Utility_Functions")), "-begin");
addpath(genpath(fullfile(repo_root, "Neural_Networks")), "-begin");

if ~isfile(bp_table_file)
    error("The blind-pass table was not found:\n%s", bp_table_file);
end

if options.ModelFile == ""
    options.ModelFile = fullfile(repo_root, "Neural_Networks", ...
        "group_pair_nn", "group_pair_nn_rec10_9_features.mat");
end

if ~isfile(options.ModelFile)
    error("The trained group-pair model was not found:\n%s\n\n" + ...
        "Make sure the model file is included in Neural_Networks/group_pair_nn.", ...
        options.ModelFile);
end

model = load(options.ModelFile, "final_net", "feature_names", ...
    "feature_mean", "feature_std", "probability_cutoff", ...
    "support_cutoff");
validate_trained_model(model);

if isempty(options.ProbabilityCutoff)
    probability_cutoff = double(model.probability_cutoff);
else
    probability_cutoff = double(options.ProbabilityCutoff);
end
if isempty(options.SupportCutoff)
    support_cutoff = double(model.support_cutoff);
else
    support_cutoff = double(options.SupportCutoff);
end

if probability_cutoff < 0 || probability_cutoff > 1 || ...
        support_cutoff < 0 || support_cutoff > 1
    error("Probability and support cutoffs must be between 0 and 1.");
end

fprintf("\nLoading and checking the blind-pass table...\n");
input = load_pipeline_input(bp_table_file);

if options.OutputFolder == ""
    options.OutputFolder = fullfile(repo_root, "Default_Results_Dir", ...
        input.recording_name, "group_pair_nn_pipeline");
end
if ~isfolder(options.OutputFolder)
    mkdir(options.OutputFolder);
end

fprintf("recording:                 %s\n", input.recording_name);
fprintf("clusters in input table:   %d\n", height(input.bp));
fprintf("structurally valid rows:   %d\n", numel(input.valid_row_indices));
fprintf("minimum spikes:            %d\n", options.MinimumSpikes);
fprintf("merge probability cutoff:  %.4f\n", probability_cutoff);
fprintf("support cutoff:            %.2f\n", support_cutoff);
fprintf("results:                   %s\n", options.OutputFolder);

worker_count = start_pipeline_workers(options.NumberOfWorkers);

matrix_file = fullfile(options.OutputFolder, ...
    "complete_ensemble_merge_matrix.mat");
matrix_checkpoint_file = fullfile(options.OutputFolder, ...
    "complete_ensemble_merge_matrix_checkpoint.mat");

matrix_result = build_full_ensemble_matrix(input.bp, ...
    input.valid_row_indices, bp_table_file, matrix_file, ...
    matrix_checkpoint_file, repo_root, worker_count, ...
    options.RebuildMatrix);

valid_bp = input.bp(input.valid_row_indices, :);
valid_spike_count = input.spike_count(input.valid_row_indices);
has_accuracy = ismember("accuracy", ...
    string(valid_bp.Properties.VariableNames));
has_ground_truth = ismember("Max_Overlap_Unit", ...
    string(valid_bp.Properties.VariableNames));

if has_accuracy
    accuracy_cutoffs = unique(options.AccuracyCutoffs(:), "stable");
    if isempty(accuracy_cutoffs) || any(~isfinite(accuracy_cutoffs)) || ...
            any(accuracy_cutoffs < 0 | accuracy_cutoffs > 100)
        error("AccuracyCutoffs must contain values from 0 through 100.");
    end
    valid_accuracy = valid_bp{:, "accuracy"};
else
    accuracy_cutoffs = NaN;
    valid_accuracy = [];
    fprintf("\nNo accuracy column was found. Running one result without " + ...
        "an accuracy filter.\n");
end

accuracy_sweep_summary = table();
result_files = strings(numel(accuracy_cutoffs), 1);

for cutoff_id = 1:numel(accuracy_cutoffs)
    accuracy_cutoff = accuracy_cutoffs(cutoff_id);
    cutoff_tag = make_cutoff_tag(accuracy_cutoff);
    result_file = fullfile(options.OutputFolder, ...
        cutoff_tag + "_grouping_result.mat");
    probability_file = fullfile(options.OutputFolder, ...
        cutoff_tag + "_pair_probabilities.mat");
    result_files(cutoff_id) = string(result_file);

    if isfile(result_file)
        saved = load(result_file, "grouping_summary", "source_matrix_file", ...
            "source_model_file", "minimum_spikes", "probability_cutoff", ...
            "support_cutoff");
        result_matches = string(saved.source_matrix_file) == string(matrix_file) && ...
            string(saved.source_model_file) == string(options.ModelFile) && ...
            saved.minimum_spikes == options.MinimumSpikes && ...
            saved.probability_cutoff == probability_cutoff && ...
            saved.support_cutoff == support_cutoff;

        if result_matches
            fprintf("\n%s is already complete; loading the saved result.\n", ...
                cutoff_tag);
            accuracy_sweep_summary = [accuracy_sweep_summary; ...
                saved.grouping_summary]; %#ok<AGROW>
            continue
        end
        error("The existing result uses different settings:\n%s", result_file);
    end

    if has_accuracy
        keep_valid_row = valid_spike_count >= options.MinimumSpikes & ...
            valid_accuracy >= accuracy_cutoff;
        fprintf("\n============================================================\n");
        fprintf("accuracy cutoff: %.1f%%\n", accuracy_cutoff);
    else
        keep_valid_row = valid_spike_count >= options.MinimumSpikes;
        fprintf("\n============================================================\n");
        fprintf("no accuracy filter\n");
    end

    kept_valid_positions = find(keep_valid_row);
    kept_row_indices = input.valid_row_indices(kept_valid_positions);
    bp_filtered = valid_bp(kept_valid_positions, :);
    filtered_matrix = logical(matrix_result.merge_matrix( ...
        kept_valid_positions, kept_valid_positions));

    fprintf("clusters kept: %d\n", height(bp_filtered));
    if isempty(kept_row_indices)
        warning("No clusters passed this cutoff. The result was skipped.");
        continue
    end

    remove_conflicts_groups = make_remove_conflicts_groups(filtered_matrix);
    fprintf("remove_conflicts groups: %d\n", ...
        numel(remove_conflicts_groups));

    merge_probability = calculate_group_pair_probabilities(bp_filtered, ...
        remove_conflicts_groups, model, probability_file, ...
        kept_row_indices, worker_count);

    [nn_groups, safe_merges, candidate_links] = ...
        merge_groups_with_support(remove_conflicts_groups, ...
        merge_probability, probability_cutoff, support_cutoff);

    if has_ground_truth
        max_overlap_unit = bp_filtered{:, "Max_Overlap_Unit"};
        original_unit_count = numel(unique( ...
            input.bp{:, "Max_Overlap_Unit"}));
    else
        max_overlap_unit = [];
        original_unit_count = NaN;
    end

    [group_summary, unit_summary, grouping_summary] = ...
        evaluate_grouping(nn_groups, max_overlap_unit, ...
        original_unit_count, accuracy_cutoff, probability_cutoff, ...
        support_cutoff, height(bp_filtered), ...
        numel(remove_conflicts_groups), candidate_links, safe_merges);

    groups_original_rows = cellfun( ...
        @(members) kept_row_indices(members), nn_groups, ...
        "UniformOutput", false);
    source_matrix_file = matrix_file;
    source_model_file = options.ModelFile;
    minimum_spikes = options.MinimumSpikes;

    save(result_file, "accuracy_cutoff", "kept_row_indices", ...
        "remove_conflicts_groups", "nn_groups", "groups_original_rows", ...
        "group_summary", "unit_summary", "grouping_summary", ...
        "probability_file", "probability_cutoff", "support_cutoff", ...
        "minimum_spikes", "source_matrix_file", "source_model_file", ...
        "-v7.3");

    disp(grouping_summary);
    accuracy_sweep_summary = [accuracy_sweep_summary; ...
        grouping_summary]; %#ok<AGROW>
end

if isempty(accuracy_sweep_summary)
    error("The pipeline did not produce any completed cutoff results.");
end

summary_file = save_pipeline_summary(accuracy_sweep_summary, ...
    result_files, bp_table_file, matrix_file, options.ModelFile, ...
    options.OutputFolder, toc(total_tic));

fprintf("\nPipeline complete.\n");
fprintf("summary: %s\n", summary_file);
fprintf("total time: %.1f minutes\n", toc(total_tic) / 60);
end
