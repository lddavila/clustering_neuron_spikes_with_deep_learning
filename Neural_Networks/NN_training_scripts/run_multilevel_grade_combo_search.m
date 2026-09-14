function results_table = run_multilevel_grade_combo_search(varargin)
%RUN_MULTILEVEL_GRADE_COMBO_SEARCH
%
% At each level k, for each threshold independently:
%   1. Generate candidate k-combos by joining that threshold's surviving
%      (k-1)-combos that share (k-2) grades (standard Apriori join), THEN
%      discard any candidate for which even one of its k immediate
%      (k-1)-subsets is not itself a survivor of that threshold's
%      previous level. If a (k-1)-combo never made it into that
%      threshold's survivors, no k-combo containing it is ever generated
%      or trained for that threshold.
%   2. All still-active thresholds' candidates for this level are pooled
%      and trained/scored together in one parfor call. Each trained
%      network is saved to disk the instant it's trained/scored (see
%      par_save_combo_network.m), so a crash mid-level only loses work
%      still in flight.
%   3. Per threshold: a trained k-combo is blacklisted if its score is
%      worse than ANY of its k immediate (k-1)-subset scores AT THAT SAME
%      THRESHOLD (all guaranteed present in results_table from step 1).
%   4. Per threshold: survivors of level k seed level k+1 for that
%      threshold. A threshold drops out of future levels once it has no
%      survivors or no valid candidates; the level loop as a whole stops
%      once every threshold has dropped out, or the level reaches the
%      total number of grades.
%
% file - save all neural networks and accuracies/scores . accuracies/scores
% as name of file? - DONE, see par_save_combo_network.m + net_save_dir below.
% par_save - DONE, see par_save_combo_network.m.
%


% first split training/validation/testing, and then split
% custom function to split data with a good cross-section for accuracy? -
% DONE
% track progression pipelines
% replace varargin if too many inputs.

% Example call: run_multilevel_grade_combo_search(data_to_save, 4)

[dir,~,~] = fileparts(mfilename('fullpath'));
cd(dir);
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);
disp("Finished adding path");

config = spikesort_config();

if numel(varargin) >= 1 && ~isempty(varargin{1})
    blind_pass_table = varargin{1};
else
    blind_pass_table = importdata(config.FP_TO_EVEN_NUMBERED_RECORDINGS);
end
blind_pass_table.original_row_id = (1:size(blind_pass_table,1)).';
disp("Finished loading blind pass table");

% replace varargin with ?
% num_grades_to_use lets you run less than the total number of grades
[all_padded_grades, old_to_new] = get_all_grades_with_padding(blind_pass_table,config);
total_grades_available = numel(old_to_new(:,1));
if numel(varargin) >= 3 && ~isempty(varargin{3})
    inferiority_margin = varargin{3};
else
    inferiority_margin = 0.02;
end
if numel(varargin) >= 2 && ~isempty(varargin{2})
    num_grades_to_use = varargin{2};
else
    num_grades_to_use = total_grades_available;
end
config.NAMES_OF_CURR_GRADES = config.NAMES_OF_CURR_GRADES(1:num_grades_to_use);
config.expanded_grade_idxs = config.expanded_grade_idxs(config.expanded_grade_idxs <= num_grades_to_use);

dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path( ...
    fullfile(config.parent_save_dir,"multilevel_grade_combo_search"));

%Directory where every trained network gets its own .mat file, saved
net_save_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path( ...
    fullfile(dir_to_save_results_to,"networks"));

[all_padded_grades, old_to_new] = get_all_grades_with_padding(blind_pass_table,config);
 
all_grade_ids = cell2mat(old_to_new(:,1));
thresholds = 10:10:90;
num_thresholds = numel(thresholds);
max_level = numel(all_grade_ids);
fprintf("Total grades: %d \n", ...
    max_level);
 
% Splitting data into blocks
num_blocks = 10;
data_blocks = build_drafted_data_blocks(blind_pass_table, num_blocks);
fprintf("Built %d drafted data blocks \n", ...
    num_blocks);
 
% Big Results Table 
results_table = table('Size',[0 6], ...
    'VariableTypes',{'cell','double','double','double','logical','cell'}, ...
    'VariableNames',{'grades','level','threshold','score','blacklisted','net_file'});

survivors_by_threshold = cell(num_thresholds,1);
active = true(num_thresholds,1);

% Level 2: every threshold starts from the same pairs
level = 2;
base_pairs = num2cell(nchoosek(all_grade_ids,2),2);

combo_list = repmat(base_pairs, num_thresholds, 1);
threshold_list = repelem(thresholds(:), numel(base_pairs), 1);

fprintf("Level %d: %d candidates pooled across %d thresholds\n", ...
    level, numel(combo_list), num_thresholds);

level_results = train_and_score_combo_list(combo_list, data_blocks, num_blocks, ...
    all_padded_grades, old_to_new, threshold_list, config, net_save_dir, level);

level_results.blacklisted = false(height(level_results),1); % no parents to compare to
results_table = [results_table; level_results];
save(fullfile(dir_to_save_results_to,"results_table_running.mat"),'results_table');

for t = 1:num_thresholds
    rows_t = level_results(level_results.threshold == thresholds(t), :);
    survivors_by_threshold{t} = rows_t.grades(~rows_t.blacklisted);
    active(t) = ~isempty(survivors_by_threshold{t});
    fprintf("  Threshold %d: %d survivors after level %d\n", ...
        thresholds(t), numel(survivors_by_threshold{t}), level);
end

% Levels : max_level: every active threshold pools candidates per level
for level = 3:max_level
    if ~any(active)
        fprintf("No threshold has survivors entering level %d, stopping.\n", level);
        break
    end

    combo_list = {};
    threshold_list = [];
    for t = 1:num_thresholds
        if ~active(t)
            continue
        end
        cand_t = generate_candidates_via_apriori_join(survivors_by_threshold{t}, level);
        if isempty(cand_t)
            fprintf("  Threshold %d: no valid candidates at level %d, dropping out.\n", thresholds(t), level);
            active(t) = false;
            continue
        end
        combo_list = [combo_list; cand_t]; 
        threshold_list = [threshold_list; repmat(thresholds(t), numel(cand_t), 1)];
    end

    if isempty(combo_list)
        fprintf("No valid candidates at level %d across any threshold, stopping.\n", level);
        break
    end

    fprintf("Level %d: %d candidates pooled across %d active thresholds\n", ...
        level, numel(combo_list), sum(active));

    level_results = train_and_score_combo_list(combo_list, data_blocks, num_blocks, ...
        all_padded_grades, old_to_new, threshold_list, config, net_save_dir, level);

    % blacklist: worse than any of its k immediate (k-1)-subsets' scores,
    level_results.blacklisted = false(height(level_results),1);
    for i = 1:height(level_results)
        combo = level_results.grades{i};
        this_threshold = level_results.threshold(i);
        parent_subsets = get_immediate_subsets(combo);
        parent_scores = nan(numel(parent_subsets),1);
        for j = 1:numel(parent_subsets)
            parent_scores(j) = lookup_score(results_table, parent_subsets{j}, this_threshold);
        end
        level_results.blacklisted(i) = level_results.score(i) < max(parent_scores) - inferiority_margin;
    end

    results_table = [results_table; level_results];
    save(fullfile(dir_to_save_results_to,"results_table_running.mat"),'results_table');

    for t = 1:num_thresholds
        if ~active(t)
            continue
        end
        rows_t = level_results(level_results.threshold == thresholds(t), :);
        survivors_by_threshold{t} = rows_t.grades(~rows_t.blacklisted);
        active(t) = ~isempty(survivors_by_threshold{t});
        fprintf("  Threshold %d: %d survivors after level %d\n", ...
            thresholds(t), numel(survivors_by_threshold{t}), level);
    end
end

% Per-threshold snapshot, so any one threshold's results are grabbable
for t = 1:num_thresholds
    threshold_rows = results_table(results_table.threshold == thresholds(t), :); 
    save(fullfile(dir_to_save_results_to, sprintf("results_table_threshold%d.mat", thresholds(t))), ...
        'threshold_rows');
end

save(fullfile(dir_to_save_results_to,"results_table_final.mat"),'results_table');
disp("Finished multi-level search across all thresholds");
 
end
 
 % make data blocks - blocks are contiguous by unit
function data_blocks = build_fixed_data_blocks(blind_pass_table, num_blocks)
 
all_units = sort(unique(blind_pass_table{:,"Max_Overlap_Unit"}));
n_units = numel(all_units);
block_boundaries = round(linspace(0, n_units, num_blocks+1));
 
data_blocks = struct('training_table',{},'val_table',{},'testing_table',{});
 
for b = 1:num_blocks
    idx_start = block_boundaries(b) + 1;
    idx_end   = block_boundaries(b+1);
    if idx_start > idx_end
        data_blocks(b).training_table = blind_pass_table([],:);
        data_blocks(b).val_table      = blind_pass_table([],:);
        data_blocks(b).testing_table  = blind_pass_table([],:);
        continue
    end
 
    block_units = all_units(idx_start:idx_end);
    block_rows  = blind_pass_table(ismember(blind_pass_table{:,"Max_Overlap_Unit"},block_units),:);
 
    n_block_units = numel(block_units);
    train_end = round(n_block_units * 0.70);
    val_end   = round(n_block_units * 0.85);
 
    train_units = block_units(1:train_end);
    val_units   = block_units(train_end+1:val_end);
    test_units  = block_units(val_end+1:end);
 
    data_blocks(b).training_table = block_rows(ismember(block_rows{:,"Max_Overlap_Unit"},train_units),:);
    data_blocks(b).val_table      = block_rows(ismember(block_rows{:,"Max_Overlap_Unit"},val_units),:);
    data_blocks(b).testing_table  = block_rows(ismember(block_rows{:,"Max_Overlap_Unit"},test_units),:);
end
 
end
 
 
function data_blocks = build_drafted_data_blocks(data_table, num_blocks, train_frac, val_frac, accuracy_agg_fn, rng_seed)
%BUILD_DRAFTED_DATA_BLOCKS
% "accuracy" here is the cluster-to-unit match quality column, NOT neural
% network accuracy.
%
% Algorithm (unit-level throughout, so no unit's rows ever cross between
% training/validation/testing -- that would be leakage):
%   1. Collapse each unit's rows to one representative accuracy value.
%   2. Randomly split ALL units once, 70/15/15, into training/validation/
%      testing sets. This is a single global split -- it happens before
%      any block exists.
%   3. Independently within EACH of those three sets: sort its units by
%      accuracy, then draft them round-robin into num_blocks blocks --
%      unit rank 1 -> block 1, rank 2 -> block 2, ..., rank (num_blocks+1)
%      -> block 1 again, and so on. This is done separately for training,
%      validation, and testing, so e.g. block 3's training units are a
%      completely independent draft from block 3's validation units.
%   4. A block's training_table/val_table/testing_table is just every row
%      belonging to the units that landed in that block for that split.
%

if nargin < 2 || isempty(num_blocks)
    num_blocks = 10;
end
if nargin < 3 || isempty(train_frac)
    train_frac = 0.70;
end
if nargin < 4 || isempty(val_frac)
    val_frac = 0.15;
end
if nargin < 5 || isempty(accuracy_agg_fn)
    accuracy_agg_fn = @mean;
end
if nargin < 6
    rng_seed = 42;
end

%  One representative accuracy value per unit
[units, ~, unit_row_idx] = unique(data_table{:,"Max_Overlap_Unit"});
n_units = numel(units);

unit_accuracy = nan(n_units,1);
for u = 1:n_units
    unit_accuracy(u) = accuracy_agg_fn(data_table{unit_row_idx==u,"accuracy"});
end

bad_units = isnan(unit_accuracy);
if any(bad_units)
    fprintf("build_drafted_data_blocks: dropping %d unit(s) with NaN/undefined accuracy.\n", ...
        sum(bad_units));
    units = units(~bad_units);
    unit_accuracy = unit_accuracy(~bad_units);
    n_units = numel(units);
end

% 2. Random 70/15/15 split of all units, once, up front 
if ~isempty(rng_seed)
    prior_rng_state = rng;
    rng(rng_seed, 'twister');
end

shuffle_order = randperm(n_units);
units = units(shuffle_order);
unit_accuracy = unit_accuracy(shuffle_order);

if ~isempty(rng_seed)
    rng(prior_rng_state); 
end

n_train = round(n_units * train_frac);
n_val   = round(n_units * val_frac);
n_val   = min(n_val, n_units - n_train);

split_units = struct( ...
    'train', units(1:n_train), ...
    'val',   units(n_train+1 : n_train+n_val), ...
    'test',  units(n_train+n_val+1 : end));
split_accuracy = struct( ...
    'train', unit_accuracy(1:n_train), ...
    'val',   unit_accuracy(n_train+1 : n_train+n_val), ...
    'test',  unit_accuracy(n_train+n_val+1 : end));

fprintf("build_drafted_data_blocks: %d units -> %d train / %d val / %d test\n", ...
    n_units, n_train, n_val, n_units-n_train-n_val);

% 3. Within each split independently: rank by accuracy, draft round-robin
split_names = {'train','val','test'};
drafted = struct('train',{repmat({[]},num_blocks,1)}, ...
                  'val',  {repmat({[]},num_blocks,1)}, ...
                  'test', {repmat({[]},num_blocks,1)});

for s = 1:numel(split_names)
    name = split_names{s};
    these_units = split_units.(name);
    these_acc   = split_accuracy.(name);

    [~, rank_order] = sort(these_acc); % ascending by accuracy
    ranked_units = these_units(rank_order);

    for n = 1:numel(ranked_units)
        b = mod(n-1, num_blocks) + 1;
        drafted.(name){b} = [drafted.(name){b}; ranked_units(n)];
    end
end

% 4. Create block's tables
data_blocks = struct('training_table',{},'val_table',{},'testing_table',{});
for b = 1:num_blocks
    data_blocks(b).training_table = data_table(ismember(data_table{:,"Max_Overlap_Unit"}, drafted.train{b}), :);
    data_blocks(b).val_table      = data_table(ismember(data_table{:,"Max_Overlap_Unit"}, drafted.val{b}), :);
    data_blocks(b).testing_table  = data_table(ismember(data_table{:,"Max_Overlap_Unit"}, drafted.test{b}), :);

    fprintf("  Block %d: %d train units, %d val units, %d test units\n", ...
        b, numel(drafted.train{b}), numel(drafted.val{b}), numel(drafted.test{b}));
end

end


%NOT USED
function data_blocks = build_stratified_data_blocks(data_table, num_blocks, num_strata, accuracy_agg_fn, rng_seed)

if nargin < 3 || isempty(num_strata)
    num_strata = 10;
end
if nargin < 4 || isempty(accuracy_agg_fn)
    accuracy_agg_fn = @mean;
end
if nargin < 5
    rng_seed = 42;
end

train_frac = 0.70;
val_frac   = 0.15;

[units, ~, unit_row_idx] = unique(data_table{:,"Max_Overlap_Unit"});
n_units = numel(units);

unit_accuracy = nan(n_units,1);
for u = 1:n_units
    unit_accuracy(u) = accuracy_agg_fn(data_table{unit_row_idx==u,"accuracy"});
end

bad_units = isnan(unit_accuracy);
if any(bad_units)
    fprintf("build_stratified_data_blocks: dropping %d unit(s) with NaN/undefined accuracy.\n", ...
        sum(bad_units));
    units = units(~bad_units);
    unit_accuracy = unit_accuracy(~bad_units);
    n_units = numel(units);
end

num_strata = max(1, min(num_strata, n_units));
quantile_edges = quantile(unit_accuracy, linspace(0,1,num_strata+1));
quantile_edges = unique(quantile_edges); % dedupe in case of repeated accuracy values
quantile_edges(1) = -inf;
quantile_edges(end) = inf;
if numel(quantile_edges) < 2
    quantile_edges = [-inf, inf]; % all units identical accuracy -> one stratum
end
strata_idx = discretize(unit_accuracy, quantile_edges);

fprintf("build_stratified_data_blocks: %d units into %d accuracy strata\n", ...
    n_units, max(strata_idx));

train_units = repmat({[]}, num_blocks, 1);
val_units   = repmat({[]}, num_blocks, 1);
test_units  = repmat({[]}, num_blocks, 1);

if ~isempty(rng_seed)
    prior_rng_state = rng;
    rng(rng_seed, 'twister');
end

for s = 1:max(strata_idx)
    stratum_units = units(strata_idx == s);
    stratum_units = stratum_units(randperm(numel(stratum_units)));

    n_s = numel(stratum_units);
    n_train = round(n_s * train_frac);
    n_val   = round(n_s * val_frac);
    n_val = min(n_val, n_s - n_train);

    train_part = stratum_units(1:n_train);
    val_part   = stratum_units(n_train+1 : n_train+n_val);
    test_part  = stratum_units(n_train+n_val+1 : end);

    train_units = local_round_robin_assign(train_units, train_part, num_blocks);
    val_units   = local_round_robin_assign(val_units, val_part, num_blocks);
    test_units  = local_round_robin_assign(test_units, test_part, num_blocks);
end

if ~isempty(rng_seed)
    rng(prior_rng_state); % don't leak the fixed seed into the rest of the caller's session
end

data_blocks = struct('training_table',{},'val_table',{},'testing_table',{});
for b = 1:num_blocks
    data_blocks(b).training_table = data_table(ismember(data_table{:,"Max_Overlap_Unit"}, train_units{b}), :);
    data_blocks(b).val_table      = data_table(ismember(data_table{:,"Max_Overlap_Unit"}, val_units{b}), :);
    data_blocks(b).testing_table  = data_table(ismember(data_table{:,"Max_Overlap_Unit"}, test_units{b}), :);

    fprintf("  Block %d: %d train units, %d val units, %d test units\n", ...
        b, numel(train_units{b}), numel(val_units{b}), numel(test_units{b}));
end

end

function lists = local_round_robin_assign(lists, items, num_blocks)
for i = 1:numel(items)
    b = mod(i-1, num_blocks) + 1;
    lists{b} = [lists{b}; items(i)];
end
end
 
 
% Generate next level
function candidates = generate_candidates_via_apriori_join(survivors, target_level)
 
k_minus_1 = target_level - 1;
n = numel(survivors);
 
survivor_keys = cellfun(@(v) mat2str(sort(v)), survivors, 'UniformOutput', false);
survivor_set = containers.Map(survivor_keys, num2cell(1:n));
 
candidate_set = containers.Map('KeyType','char','ValueType','any');
 
for i = 1:n
    combo_i = sort(survivors{i});
    for j = i+1:n
        combo_j = sort(survivors{j});
        if k_minus_1 >= 2 && ~isequal(combo_i(1:end-1), combo_j(1:end-1))
            continue
        end
        merged = union(combo_i, combo_j);
        if numel(merged) ~= target_level
            continue
        end
        key = mat2str(sort(merged));
        if isKey(candidate_set, key)
            continue
        end
 
        subsets = get_immediate_subsets(merged);
        all_present = true;
        for s = 1:numel(subsets)
            if ~isKey(survivor_set, mat2str(sort(subsets{s})))
                all_present = false;
                break
            end
        end
        if all_present
            candidate_set(key) = sort(merged);
        end
    end
end
 
candidates = values(candidate_set);
candidates = candidates(:);
 
end
 
 
% Get all immediate parents of a combination
function subsets = get_immediate_subsets(combo)
combo = sort(combo);
k = numel(combo);
subsets = cell(k,1);
for i = 1:k
    s = combo;
    s(i) = [];
    subsets{i} = s;
end
end
 
 
% Get score for a combo AT A SPECIFIC THRESHOLD -- thresholds are
% independent searches, so a lookup must never cross between them.
% NOT USED
function score = lookup_score(results_table, combo, threshold)
target_key = mat2str(sort(combo));
same_threshold = results_table(results_table.threshold == threshold, :);
idx = find(cellfun(@(v) isequal(mat2str(sort(v)), target_key), same_threshold.grades), 1);
if isempty(idx)
    error("lookup_score: combo %s not found in results_table for threshold %d -- this should never happen " + ...
        "if Apriori pruning ran correctly.", target_key, threshold);
end
score = same_threshold.score(idx);
end