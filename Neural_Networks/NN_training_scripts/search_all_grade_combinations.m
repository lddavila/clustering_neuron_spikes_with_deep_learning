function [] = search_all_grade_combinations(options)
arguments
    options.blind_pass_table table = cell2table(cell(0,1));
end

addpath(genpath(pwd))
config = spikesort_config();

% settings
opts = default_opts();

% load table
if size(options.blind_pass_table) == 0
    blind_pass_table = importdata(config.FP_TO_EVEN_NUMBERED_RECORDINGS);
else
    blind_pass_table = options.blind_pass_table;
end
disp("Finished loading blind pass table");

% save locations
results_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path( ...
    fullfile(config.parent_save_dir,"grade_combination_search"));
cache_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path( ...
    fullfile(results_dir,"cache"));

% build grades matrix and drop NaN rows
all_grades_formatted = [cell2mat(assemble_data_for_neural_net("grades 3",blind_pass_table,config))];
keep = ~any(isnan(all_grades_formatted),2);
grades = all_grades_formatted(keep,:);
% 0/1 class the net predicts
labels = double(blind_pass_table{keep,"is_neuron"});   

num_grades = size(grades,2);
fprintf("Grades matrix has %d columns and %d rows.\n",num_grades,size(grades,1));

% split once and reuse for every combination
rng(0);
[tr_idx,val_idx,te_idx] = make_split(size(grades,1),opts);

% parallel pool
start_pool(opts.num_workers);

% == backward elimination ==
% start with all grades, then remove one at a time. removing a grade is kept
% only if accuracy does not drop more than drop_tol. a grade whose removal
% makes it worse is locked and never removed again,
% so every combination that would have dropped an important grade is skipped.

current_cols = 1:num_grades;               
locked = false(1,num_grades);     

base = train_and_score(current_cols,grades,labels,tr_idx,val_idx,te_idx,cache_dir,opts);
fprintf("Full set (%d grades) accuracy: %.4f\n",num_grades,base.test_acc);
base = base.test_acc;

round_num = 0;
changed = true;
while changed
    changed = false;
    round_num = round_num + 1;

    removable = current_cols(~locked(current_cols));
    round_rows = cell(numel(removable),1);

    % train every leave-one-out candidate for this round in parallel
    parfor r = 1:numel(removable)
        g = removable(r);
        trial_cols = current_cols(current_cols ~= g);
        res = train_and_score(trial_cols,grades,labels,tr_idx,val_idx,te_idx,cache_dir,opts);
        round_rows{r} = struct('removed_grade',g,'test_acc',res.test_acc);
    end
    round_rows = vertcat(round_rows{:});

    % find removal that keeps accuracy highest
    [best_acc,best_i] = max([round_rows.test_acc]);
    best_grade = round_rows(best_i).removed_grade;

    if best_acc >= base - opts.drop_tol
        % removing this grade is fine (up / stayed same) 
        current_cols = current_cols(current_cols ~= best_grade);
        base = best_acc;
        changed = true;
        fprintf("round %d: removed grade %d, acc=%.4f (kept %d grades)\n", ...
            round_num,best_grade,best_acc,numel(current_cols));
    else
        % all remaining removable grades are essential
        locked(removable) = true;
        fprintf("round %d: no removal safe (best would drop to %.4f). done.\n", ...
            round_num,best_acc);
    end

    save_round_summary(results_dir,round_num,round_rows,current_cols,base);
end

fprintf("\nFinal essential grade set (%d grades): %s\n", ...
    numel(current_cols),strjoin(string(current_cols),"-"));
fprintf("Final accuracy: %.4f\n",base);
fprintf("Results in:\n  %s\n",results_dir);
end


% ==================================
% helper functions


function opts = default_opts()
opts = struct();
% allowed accuracy drop to still remove a grade
opts.drop_tol          = 0.02;   
opts.num_workers       = 10;
opts.neurons_per_layer = 5;
opts.num_layers        = 5;
opts.batch_size        = 32;
opts.test_frac         = 0.20;
opts.val_frac          = 0.20;
end

function start_pool(num_workers)
if isempty(gcp('nocreate'))
    try
        parpool(num_workers);
    catch
        parpool;
    end
end
end

function [tr_idx,val_idx,te_idx] = make_split(n,opts)
perm = randperm(n);
n_test = round(opts.test_frac*n);
te_idx = perm(1:n_test);
rest = perm(n_test+1:end);
n_val = round(opts.val_frac*numel(rest));
val_idx = rest(1:n_val);
tr_idx = rest(n_val+1:end);
end

function result = train_and_score(cols,grades,labels,tr_idx,val_idx,te_idx,cache_dir,opts)
% Using cache, train one net on the given grade columns & return test accuracy. 
cols = sort(cols);
cache_file = fullfile(cache_dir,combo_key(cols)+".mat");
if isfile(cache_file)
    s = load(cache_file);
    fn = fieldnames(s);         
    result = s.(fn{1});        
    return;
end

X = grades(:,cols);
col_min = min(X(tr_idx,:));
col_max = max(X(tr_idx,:));
X = rescale(X,-1,1,"InputMin",col_min,"InputMax",col_max);

% two sets of data: training and validation. 
training_data   = build_data_table(X(tr_idx,:),  labels(tr_idx));
validation_data = build_data_table(X(val_idx,:), labels(val_idx));

% first arg is number of features in this combination
layers = dynamically_create_layers_for_nn(numel(cols),opts.neurons_per_layer,opts.num_layers,2);
% test_nn_on_incremental_challenging returns [accuracy, net]
[~,trained_net] = test_nn_on_incremental_challenging(training_data,validation_data,layers,opts.batch_size);

scores = predict(trained_net,X(te_idx,:));
[~,YPred] = max(scores,[],2);
YPred = YPred-1;
YTest = labels(te_idx);
test_acc = sum(YPred==YTest)/numel(YTest);

result = struct('cols',cols,'test_acc',test_acc,'col_min',col_min,'col_max',col_max,'ok',true);
par_save(cache_file,result);
end

function T = build_data_table(Xrows,y
T = array2table(Xrows);
T.label = categorical(y,[0 1]);
end

function key = combo_key(cols)
% function to make filename for any column set (from online) 
cols = sort(cols(:)');
n = max(cols);
present = false(1,n);
present(cols) = true;
hexchars = '0123456789ABCDEF';
hexstr = '';
for start_bit = 1:4:n
    nibble_bits = present(start_bit:min(start_bit+3,n));
    weights = 2.^(0:numel(nibble_bits)-1);        
    val = sum(nibble_bits .* weights);
    hexstr = [hexchars(val+1), hexstr];           %#ok<AGROW>
end
key = "g" + numel(cols) + "_" + string(hexstr);
end

function save_round_summary(results_dir,round_num,round_rows,current_cols,base)
removed = [round_rows.removed_grade]';
acc = [round_rows.test_acc]';
T = sortrows(table(removed,acc,'VariableNames',{'grade_removed','acc_without_it'}), ...
    'acc_without_it','descend');
writetable(T,fullfile(results_dir,sprintf("round_%d_leave_one_out.csv",round_num)));

writetable(table(current_cols','VariableNames',{'kept_grades'}), ...
    fullfile(results_dir,sprintf("round_%d_kept.csv",round_num)));
end
