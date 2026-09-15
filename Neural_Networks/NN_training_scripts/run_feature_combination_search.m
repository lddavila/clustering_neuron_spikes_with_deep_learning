function [results_table] = run_feature_combination_search(varargin)
% ONE-FILE FRAMEWORK: exhaustive feature-combination search for
% train_prob_dist_nn_equ_diff_grades_3_w_temp_scaling.
%
%   * tests EVERY combination of the candidate grade features (2^N - 1)
%   * runs combinations in parallel with parfor
%   * processes combinations in waves of increasing size, so a bad PAIR found
%     at size 2 prunes every larger combination containing that pair
%   * checkpoints after every batch, so a rerun resumes at combination 10,001
%     if 10,000 finished last time
%   * each combination trains nets only at thresholds [1, 10, 20, ... 100]
%
% USAGE:
%   run_feature_combination_search();
%   run_feature_combination_search('DropTolerance',0.05,'BatchSize',64);
%   run_feature_combination_search('Features',["grades 1","grades 2","grades 3"]);

% ------------------------------------------------------------------
% path setup (same idea as the original function, done once, up front)
% ------------------------------------------------------------------
[this_dir,~,~] = fileparts(mfilename('fullpath'));
old_dir = cd(this_dir);
cd("..");
cd("..");
addpath(genpath(pwd));
cd(old_dir);
disp("Finished adding path");

% ------------------------------------------------------------------
% options
% ------------------------------------------------------------------
p = inputParser;
addParameter(p,'Features',["grades 1","grades 2","grades 3","grades 4", ...
                           "grades 5","grades 6","grades 7","grades 8"]);
addParameter(p,'ScoreMetric','mean_accuracy');  % mean_accuracy | mean_auc | neg_mean_brier
addParameter(p,'DropTolerance',0.05);           % "drastic" drop = 5 accuracy points
addParameter(p,'BatchSize',32);                 % combos per parfor batch before checkpoint
addParameter(p,'MaxCombos',Inf);                % stop early (handy for a smoke test)
addParameter(p,'NumWorkers',[]);
addParameter(p,'SearchName',"feature_combination_search");
parse(p,varargin{:});
opt = p.Results;

features = string(opt.Features);
N = numel(features);
assert(N <= 20,"2^N combinations becomes unreasonable above ~20 features.");

config = spikesort_config();
disp("Finished getting config");

search_root = create_a_file_if_it_doesnt_exist_and_ret_abs_path( ...
    fullfile(config.parent_save_dir, opt.SearchName));
nets_root = create_a_file_if_it_doesnt_exist_and_ret_abs_path( ...
    fullfile(search_root,"nets"));
ckpt_file = fullfile(search_root,"checkpoint.mat");

% load the blind pass table ONCE; it is broadcast to the workers
blind_pass_table = importdata(config.FP_TO_EVEN_NUMBERED_RECORDINGS);
disp("Finished loading blind pass table");

% ------------------------------------------------------------------
% resume from checkpoint
% ------------------------------------------------------------------
state = load_or_init_checkpoint(ckpt_file, features, opt);
fprintf("Resuming: %d/%d combinations complete, %d pruned, %d banned pairs.\n", ...
    nnz(state.done), 2^N-1, nnz(state.pruned), nnz(triu(state.banned_pairs,1)));

% ------------------------------------------------------------------
% pool
% ------------------------------------------------------------------
if isempty(gcp('nocreate'))
    if isempty(opt.NumWorkers), parpool(); else, parpool(opt.NumWorkers); end
end

% ------------------------------------------------------------------
% enumerate every subset as a bitmask, ordered by subset size
% ------------------------------------------------------------------
all_masks = (1:(2^N-1))';
sizes = sum(dec2bin(all_masks,N)=='1',2);
n_run = 0;

for k = 1:N                                     % wave = combination size
    wave = all_masks(sizes==k);

    keep = false(numel(wave),1);
    for w = 1:numel(wave)
        m = wave(w);
        if state.done(m) || state.pruned(m), continue; end
        if combo_has_banned_pair(m, state.banned_pairs, N)
            state.pruned(m) = true;             % inherited pruning
            continue;
        end
        keep(w) = true;
    end
    wave = wave(keep);
    if isempty(wave), save_checkpoint(ckpt_file,state); continue; end

    for b = 1:opt.BatchSize:numel(wave)
        batch = wave(b:min(b+opt.BatchSize-1,numel(wave)));

        % bans can grow while earlier batches run, so re-check
        batch = batch(~arrayfun(@(m) combo_has_banned_pair(m,state.banned_pairs,N), batch));
        if isempty(batch), continue; end

        if n_run + numel(batch) > opt.MaxCombos
            batch = batch(1:max(0,opt.MaxCombos - n_run));
            if isempty(batch), save_checkpoint(ckpt_file,state); break; end
        end

        batch_out = cell(numel(batch),1);
        parfor bi = 1:numel(batch)
            m = batch(bi);
            idx = find(bitget(m,1:N));
            combo_features = features(idx);
            combo_dir = fullfile(nets_root, sprintf("combo_%06d_%s", m, ...
                matlab.lang.makeValidName(strjoin(combo_features,"_"))));
            t0 = tic;
            try
                r = train_combo(blind_pass_table, combo_features, combo_dir, config);
                batch_out{bi} = struct('mask',m,'features',{combo_features}, ...
                    'mean_accuracy',mean(r.accuracy,'omitnan'), ...
                    'mean_auc',mean(r.auc,'omitnan'), ...
                    'mean_brier',mean(r.brier,'omitnan'), ...
                    'per_threshold_accuracy',r.accuracy, ...
                    'elapsed',toc(t0),'error',"");
            catch ME
                batch_out{bi} = struct('mask',m,'features',{combo_features}, ...
                    'mean_accuracy',NaN,'mean_auc',NaN,'mean_brier',NaN, ...
                    'per_threshold_accuracy',NaN,'elapsed',toc(t0), ...
                    'error',string(ME.message));
            end
        end

        for bi = 1:numel(batch_out)
            o = batch_out{bi};
            state.done(o.mask)  = true;
            state.score(o.mask) = score_of(o, opt.ScoreMetric);
            state.results(end+1) = o; %#ok<AGROW>
        end

        state = update_banned_pairs(state, N, opt.DropTolerance);
        n_run = n_run + numel(batch_out);
        save_checkpoint(ckpt_file,state);
        fprintf("Checkpoint: %d/%d done, %d pruned, %d banned pairs.\n", ...
            nnz(state.done), 2^N-1, nnz(state.pruned), nnz(triu(state.banned_pairs,1)));
    end
    if n_run >= opt.MaxCombos, break; end
end

results_table = results_to_table(state);
writetable(results_table, fullfile(search_root,"feature_search_results.csv"));
if ~isempty(results_table)
    fprintf("\nBEST COMBINATION: %s  (score = %.4f)\n", ...
        results_table.features(1), results_table.score(1));
end
end


% ==================================================================
% TRAINING (your original function, structure preserved)
% ==================================================================
function [results] = train_combo(blind_pass_table, list_of_features_to_add, dir_to_save_results_to, config)

dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_results_to);

% only 1% and every 10%
thresholds = unique([1, 10:10:100]);

%partition the blind_pass_table into training and testing data
partitioned_table_array = partition_bp_tables(blind_pass_table,0);
testing_table       = partitioned_table_array{1,2};
training_table_full = partitioned_table_array{1,1};

%parition the training table into training and validation data
partitioned_training_table = partition_bp_tables(training_table_full,0);
training_table_full = partitioned_training_table{1,1};
val_table           = partitioned_training_table{1,2};

results = struct('features',{list_of_features_to_add},'thresholds',thresholds, ...
    'accuracy',nan(1,numel(thresholds)),'auc',nan(1,numel(thresholds)), ...
    'brier',nan(1,numel(thresholds)),'temperature',nan(1,numel(thresholds)));

last_net_names = [];
for i = 1:length(thresholds)
    rng(0)
    current_threshold = thresholds(i);
    training_table = training_table_full;      % fresh copy each threshold

    thresh_mag_diff = abs(training_table{:,"accuracy"}-current_threshold);
    difficulty_buckets = [0,5,10,15,20,25,Inf];

    training_diff_buckets = get_difficulty_buckets_array(thresh_mag_diff,difficulty_buckets,1);
    training_table.difficulty_buckets = training_diff_buckets;
    training_table(isnan(training_table{:,"difficulty_buckets"}),:) = [];

    equalized_training_table = equalize_classes(training_table);

    above_threshold_samples = equalized_training_table(equalized_training_table{:,"accuracy"}>current_threshold,:);
    below_threshold_samples = equalized_training_table(equalized_training_table{:,"accuracy"}<=current_threshold,:);

    min_num_samples_per_class = min([size(above_threshold_samples,1),size(below_threshold_samples,1)]);
    if min_num_samples_per_class < 1, continue; end

    rng(0);
    random_above_indexes = randperm(size(above_threshold_samples,1),min_num_samples_per_class);
    random_below_indexes = randperm(size(below_threshold_samples,1),min_num_samples_per_class);

    training_data = [above_threshold_samples(random_above_indexes,:); ...
                     below_threshold_samples(random_below_indexes,:)];
    training_data = training_data(randperm(size(training_data,1),size(training_data,1)),:);

    training_above_below_class = training_data{:,"accuracy"} > current_threshold;

    training_data = [cell2mat(assemble_data_for_neural_net(list_of_features_to_add,training_data,config))];

    nan_rows = any(isnan(training_data),2);
    training_data(nan_rows,:) = [];
    training_above_below_class(nan_rows,:) = [];

    if i~=1 && ~isempty(last_net_names)
        training_data = get_certainties_of_all_previous_nets(last_net_names,dir_to_save_results_to,training_data);
    end

    col_min = min(training_data,[],1);
    col_max = max(training_data,[],1);
    training_data = rescale(training_data,0,1,"InputMax",col_max,"InputMin",col_min);

    layers_of_net = dynamically_create_layers_for_nn(size(training_data,2),10,5,2);
    training_data = [training_data,training_above_below_class];

    val_data  = cell2mat(assemble_data_for_neural_net(list_of_features_to_add,val_table,config));
    test_data = cell2mat(assemble_data_for_neural_net(list_of_features_to_add,testing_table,config));

    if i~=1 && ~isempty(last_net_names)
        val_data  = get_certainties_of_all_previous_nets(last_net_names,dir_to_save_results_to,val_data);
        test_data = get_certainties_of_all_previous_nets(last_net_names,dir_to_save_results_to,test_data);
    end

    val_data  = rescale(val_data,0,1,"InputMax",col_max,"InputMin",col_min);
    test_data = rescale(test_data,0,1,"InputMax",col_max,"InputMin",col_min);

    val_above_below_class = val_table{:,"accuracy"} > current_threshold;
    val_data = [val_data,val_above_below_class];

    [~,net] = test_nn_on_incremental_challenging(training_data,val_data,layers_of_net,32);

    % --- Fit temperature on validation data (post-hoc calibration) ---
    val_data(any(isnan(val_data),2),:) = [];
    val_scores = predict(net, val_data(:,1:end-1));
    val_p1 = val_scores(:,2);
    val_y  = val_data(:,end);

    T = fit_temperature_binary(val_p1, val_y);
    val_p1_cal = apply_temperature_binary(val_p1, T);
    fprintf("[%s] Threshold %d: T=%.3f | Val Brier: %.4f -> %.4f\n", ...
        strjoin(list_of_features_to_add,"+"), current_threshold, T, ...
        mean((val_p1-val_y).^2), mean((val_p1_cal-val_y).^2));

    test_true_class = testing_table{:,"accuracy"} > current_threshold;
    test_data = [test_data,test_true_class];
    test_data(any(isnan(test_data),2),:) = [];

    scores   = predict(net,test_data(:,1:end-1));
    p1_cal   = apply_temperature_binary(scores(:,2), T);
    YPred    = p1_cal >= 0.5;

    accuracy    = mean(YPred == test_data(:,end));
    brier_score = mean((p1_cal - test_data(:,end)).^2);
    if numel(unique(test_data(:,end))) > 1
        [~,~,~,auc] = perfcurve(test_data(:,end), p1_cal, 1);
    else
        auc = NaN;
    end
    fprintf("Accuracy on test data: %.2f\n",accuracy*100);

    net_struct = struct();
    net_struct.net = net;
    net_struct.InputMax = col_max;
    net_struct.InputMin = col_min;
    net_struct.brier_score = brier_score;
    net_struct.auc = auc;
    net_struct.temperature = T;
    last_net_name = "above_below_"+string(current_threshold)+"_accuracy_"+sprintf("%.2f",accuracy*100)+".mat";
    par_save(fullfile(dir_to_save_results_to,last_net_name),net_struct);   % absolute path = parfor safe
    last_net_names = [last_net_names,last_net_name];

    results.accuracy(i)    = accuracy;
    results.auc(i)         = auc;
    results.brier(i)       = brier_score;
    results.temperature(i) = T;
end
end


% ==================================================================
% HELPERS
% ==================================================================
function s = score_of(o, metric)
switch lower(metric)
    case 'mean_accuracy',  s = o.mean_accuracy;
    case 'mean_auc',       s = o.mean_auc;
    case 'neg_mean_brier', s = -o.mean_brier;
    otherwise, error("Unknown ScoreMetric");
end
end

function state = load_or_init_checkpoint(ckpt_file, features, opt)
N = numel(features);
sig = string(strjoin(features,"|")) + "#" + string(opt.ScoreMetric);
if isfile(ckpt_file)
    S = load(ckpt_file,'state');
    if isfield(S,'state') && strcmp(S.state.signature,sig)
        state = S.state; return;
    end
    warning("Checkpoint signature mismatch (feature list or metric changed). Starting fresh; old file backed up.");
    movefile(ckpt_file, ckpt_file + ".bak_" + string(datetime('now','Format','yyyyMMdd_HHmmss')));
end
state = struct();
state.signature    = sig;
state.features     = features;
state.done         = false(2^N-1,1);
state.pruned       = false(2^N-1,1);
state.score        = nan(2^N-1,1);
state.banned_pairs = false(N,N);
state.results      = struct('mask',{},'features',{},'mean_accuracy',{}, ...
                            'mean_auc',{},'mean_brier',{}, ...
                            'per_threshold_accuracy',{},'elapsed',{},'error',{});
end

function save_checkpoint(ckpt_file, state)
tmp = ckpt_file + ".tmp";                 % atomic write, never lose a checkpoint
save(tmp,'state','-v7.3');
if isfile(ckpt_file), delete(ckpt_file); end
movefile(tmp, ckpt_file);
end

function tf = combo_has_banned_pair(mask, banned_pairs, N)
idx = find(bitget(mask,1:N));
tf = false;
if numel(idx) < 2, return; end
sub = banned_pairs(idx,idx);
tf = any(sub(:));
end

function state = update_banned_pairs(state, N, drop_tol)
% Ban pair (i,j) when the pair scores drastically below BOTH singletons:
%   score(i,j) < min(score(i),score(j)) - drop_tol
for r = 1:numel(state.results)
    o = state.results(r);
    idx = find(bitget(o.mask,1:N));
    if numel(idx) ~= 2 || isnan(state.score(o.mask)), continue; end
    i = idx(1); j = idx(2);
    si = state.score(bitset(0,i));
    sj = state.score(bitset(0,j));
    if isnan(si) || isnan(sj), continue; end
    if state.score(o.mask) < min(si,sj) - drop_tol
        state.banned_pairs(i,j) = true;
        state.banned_pairs(j,i) = true;
    end
end
if any(state.banned_pairs(:))
    for m = 1:numel(state.done)
        if state.done(m) || state.pruned(m), continue; end
        if combo_has_banned_pair(m, state.banned_pairs, N)
            state.pruned(m) = true;
        end
    end
end
end

function T = results_to_table(state)
n = numel(state.results);
T = table('Size',[n 7], ...
    'VariableTypes',{'double','string','double','double','double','double','string'}, ...
    'VariableNames',{'mask','features','score','mean_auc','mean_brier','elapsed_sec','error'});
for r = 1:n
    o = state.results(r);
    T.mask(r)        = o.mask;
    T.features(r)    = strjoin(o.features,"+");
    T.score(r)       = o.mean_accuracy;
    T.mean_auc(r)    = o.mean_auc;
    T.mean_brier(r)  = o.mean_brier;
    T.elapsed_sec(r) = o.elapsed;
    T.error(r)       = o.error;
end
T = sortrows(T,'score','descend');
end