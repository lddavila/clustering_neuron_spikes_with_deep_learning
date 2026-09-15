function level_results = train_and_score_combo_list(candidates, data_blocks, num_blocks, ...
    all_padded_grades, old_to_new, thresholds_vec, config, net_save_dir, level)
%TRAIN_AND_SCORE_COMBO_LIST
% Trains every (candidate, threshold) pair in ONE parfor call.
%
% Continue mechanic completed

n = numel(candidates);
if isscalar(thresholds_vec)
    thresholds_vec = repmat(thresholds_vec, n, 1);
end
thresholds_vec = thresholds_vec(:);

scores_out    = nan(n,1);
net_files_out = cell(n,1);
grades_out    = candidates;

% progress bar
q = parallel.pool.DataQueue;
afterEach(q, @print_status_bar);
print_status_bar(n, sprintf('train_and_score_combo_list (level %d)', level));

parfor i = 1:n
    combo = candidates{i};
    this_threshold = thresholds_vec(i);
    try
        [score_i, net_file_i] = train_and_score_single_combo( ...
            combo, data_blocks, num_blocks, all_padded_grades, old_to_new, this_threshold, config, ...
            net_save_dir, level);
        scores_out(i) = score_i;
        net_files_out{i} = net_file_i;
    catch ME
        fprintf(2, "Combo [%s] @ threshold %d failed: %s\n", mat2str(combo), this_threshold, ME.message);
        disp(ME.getReport)
        scores_out(i) = NaN;
        net_files_out{i} = '';
    end
    send(q, []); %#ok<PFBNS>
end

level_results = table(grades_out, repmat(level,n,1), thresholds_vec, scores_out, net_files_out, ...
    'VariableNames', {'grades','level','threshold','score','net_file'});

failed = isnan(level_results.score);
if any(failed)
    fprintf("Dropping %d combo(s) that failed to train.\n", sum(failed));
    level_results(failed,:) = [];
end

end

% Get accuracy for one combo at one threshold, and save its network
function [accuracy, net_file] = train_and_score_single_combo( ...
    grade_combo, data_blocks, num_blocks, all_padded_grades, old_to_new, threshold, config, ...
    net_save_dir, level)

accuracy = NaN;
net_file = '';

%  continue mechanic: skip if this combo/threshold was already trained 
[already_done, existing_accuracy, existing_net_file] = find_existing_net_file( ...
    net_save_dir, grade_combo, level, threshold);
if already_done
    fprintf("Combo [%s] @ threshold %d already trained, skipping (found %s)\n", ...
        mat2str(sort(grade_combo)), threshold, existing_net_file);
    accuracy = existing_accuracy;
    net_file = existing_net_file;
    return
end

block_idx = assign_block_for_combo(grade_combo, num_blocks);
training_table = data_blocks(block_idx).training_table;
val_table      = data_blocks(block_idx).val_table;
testing_table  = data_blocks(block_idx).testing_table;

grade_columns = [];
for g = 1:numel(grade_combo)
    row = find(cell2mat(old_to_new(:,1)) == grade_combo(g));
    grade_columns = [grade_columns, old_to_new{row,3}]; 
end
selected_grade_data = all_padded_grades(:,grade_columns);

thresh_mag_diff = abs(training_table{:,"accuracy"}-threshold);
difficulty_buckets = [0,5,10,15,20,25];
training_diff_buckets = get_difficulty_buckets_array(thresh_mag_diff,difficulty_buckets,1);
training_table.difficulty_buckets = training_diff_buckets;
training_table(isnan(training_table{:,"difficulty_buckets"}),:) = [];

equalized_training_table = equalize_classes(training_table);

above_threshold_samples = equalized_training_table(equalized_training_table{:,"accuracy"}>threshold,:);
below_threshold_samples = equalized_training_table(equalized_training_table{:,"accuracy"}<=threshold,:);

min_num_samples_per_class = min([size(above_threshold_samples,1),size(below_threshold_samples,1)]);
if min_num_samples_per_class == 0
    return
end

above_selected = above_threshold_samples(1:min_num_samples_per_class,:);
below_selected = below_threshold_samples(1:min_num_samples_per_class,:);

training_data = [above_selected; below_selected];
training_above_below_class = training_data{:,"accuracy"} > threshold;

training_data = selected_grade_data(training_data.original_row_id,:);
nan_rows = any(isnan(training_data),2);
training_data(nan_rows,:) = [];
training_above_below_class(nan_rows,:) = [];

col_min = min(training_data,[],1);
col_max = max(training_data,[],1);
training_data = rescale(training_data,-1,1,"InputMax",col_max,"InputMin",col_min);

layers_of_net = dynamically_create_layers_for_nn(size(training_data,2),10,5,2);

training_data = [training_data,training_above_below_class];

val_data = selected_grade_data(val_table.original_row_id,:);
val_data = rescale(val_data,-1,1,"InputMax",col_max,"InputMin",col_min);
val_above_below_class = val_table{:,"accuracy"} > threshold;
val_data = [val_data,val_above_below_class];

[~,net] = test_nn_on_incremental_challenging(training_data,val_data,layers_of_net,32);

test_data = selected_grade_data(testing_table.original_row_id,:);
test_data = rescale(test_data,-1,1,"InputMax",col_max,"InputMin",col_min);
test_true_class = testing_table{:,"accuracy"} > threshold;
test_data = [test_data,test_true_class];

scores = predict(net,test_data(:,1:end-1));
[~,YPred] = max(scores,[],2);
YPred = YPred-1;

accuracy = sum(YPred==test_data(:,end))/size(test_data,1);

net_file = par_save_combo_network(net_save_dir, grade_combo, level, threshold, accuracy, net);

clear net

end

% get block index
function block_idx = assign_block_for_combo(grade_combo, num_blocks)
block_idx = mod(sum(grade_combo), num_blocks) + 1;
end


% find_existing_net_file
% Looks for a previously-saved network for this (combo, level, threshold)
% so we can skip it.

function [found, accuracy, net_file] = find_existing_net_file(net_save_dir, combo, level, threshold)

found = false;
accuracy = NaN;
net_file = '';

combo_sorted = sort(combo);
combo_str = strjoin(string(combo_sorted), "_");
pattern = sprintf('lvl%d_grades_%s_thresh%d_acc*.mat', level, combo_str, threshold);

listing = dir(fullfile(net_save_dir, pattern));
if isempty(listing)
    return
end

candidate_file = fullfile(listing(1).folder, listing(1).name);
try
    s = load(candidate_file, 'accuracy_out');
    accuracy = s.accuracy_out;
    net_file = candidate_file;
    found = true;
catch
    % file exists but couldn't be loaded
    found = false;
    accuracy = NaN;
    net_file = '';
end

end


% par_save_combo_network
%
% Saves ONE trained network to its own .mat file, immediately, with the
% grade combo / level / threshold / accuracy  in the file name.
%
% Filename example:
% lvl3_grades_2_5_9_thresh30_acc0p8734.mat
%
% Inputs:
% net_save_dir - directory to save into (must already exist)
% combo - numeric vector of grade ids for this combo
% level - scalar, number of grades in the combo (numel(combo))
% threshold - the accuracy threshold this particular net was trained for
% accuracy - scalar test accuracy for this (combo, threshold) net
% net - the trained network object
%
% Output:
% net_file - full path to the saved .mat file
% ------------------------------------------------------------------
function net_file = par_save_combo_network(net_save_dir, combo, level, threshold, accuracy, net)

combo_sorted = sort(combo);
combo_str = strjoin(string(combo_sorted), "_");
acc_str = local_num_to_filename_str(accuracy);

fname = sprintf('lvl%d_grades_%s_thresh%d_acc%s.mat', level, combo_str, threshold, acc_str);
net_file = fullfile(net_save_dir, fname);

combo_out     = combo_sorted;    %#ok<NASGU>
level_out     = level;           %#ok<NASGU>
threshold_out = threshold;       %#ok<NASGU>
accuracy_out  = accuracy;        %#ok<NASGU>
net_out       = net;             %#ok<NASGU>

save(net_file, 'net_out', 'combo_out', 'level_out', 'threshold_out', 'accuracy_out', '-v7.3');

end

function s = local_num_to_filename_str(x)
% Turns a numeric accuracy/score into a string for filenames,
% 0.8734 -> "0p8734", -0.1 -> "neg0p1000", NaN -> "NaN"
if isnan(x)
    s = "NaN";
elseif x < 0
    s = "neg" + strrep(sprintf('%.4f', abs(x)), '.', 'p');
else
    s = strrep(sprintf('%.4f', x), '.', 'p');
end
end


% print_status_bar
%
% Simple progress bar for use with a parallel.pool.DataQueue.
%
% Call with TWO args to (re)initialize before the parfor loop:
%   print_status_bar(num_iterations, "function_name.m")
%
% Call with ZERO/ONE arg (as afterEach does via send(q,[])) to advance
% the counter by one and print the updated progress.
function print_status_bar(varargin)

persistent total count name t_start

if nargin == 2
    total = varargin{1};
    name = varargin{2};
    count = 0;
    t_start = tic;
    fprintf('%s: starting %d task(s)...\n', name, total);
    return
end

if isempty(total)
    % Guard against afterEach firing before init was ever called
    return
end

count = count + 1;
pct = 100 * count / total;
elapsed = toc(t_start);
fprintf('%s: %d/%d (%.1f%%) - elapsed %.1fs\n', name, count, total, pct, elapsed);

end