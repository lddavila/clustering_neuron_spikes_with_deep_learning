function [blind_pass_table] = add_super_nn_prediction(blind_pass_table,config)
nn_struct = importdata(config.FP_TO_super_nn);
nn = nn_struct.net();
% features_to_use = nn_struct.feature_names{1};
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
super_prediction = nan(size(sliced_bp_table,1),1);
under_unit_predictor_struct = importdata(config.FP_TO_Multi_under_units_predicting_nn);

choose_better_nn_struct = importdata(config.FP_TO_COMPLEX_CHOOSE_BETTER_NN);
choose_better_nn = choose_better_nn_struct.net;


load("C:\Users\ldd77\OneDrive\Desktop\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\rescale_params.mat");

[grade_names,all_grades]= flatten_grades_cell_array(blind_pass_table{:,"grades"},config);
[indexes_of_grades_were_looking_for,~] = find(ismember(grade_names,config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST)));
grades_array = all_grades(:,indexes_of_grades_were_looking_for);
sliced_grades = slice_table_for_parallel_processing(grades_array,[]);

four_acc_cat_predicting_nn = importdata(config.FP_TO_4_accuracy_cats_predictor);
nn_4_accuracy_cats = four_acc_cat_predicting_nn.net;
presorted_table = cell(100,1);
presorted_table_rows = nan(size(presorted_table,1),1);
estimated_rank_col = nan(size(blind_pass_table,1),1);
rng(0);
for i=1:1:100
    lower_bound = i-1;
    upper_bound = i;
    [rows_in_boundary,~] = find(blind_pass_table{:,"accuracy"}<= upper_bound & blind_pass_table{:,"accuracy"} > lower_bound);
    presorted_table_rows(i) = rows_in_boundary(randperm(size(rows_in_boundary,1),1));
    presorted_table{i}= blind_pass_table(presorted_table_rows(i),:);
end

presorted_table = vertcat(presorted_table{:});
presorted_grade_rows = grades_array(presorted_table_rows,:);

parfor i=1:size(blind_pass_table,1)
    current_data = sliced_bp_table{i};
    estimated_rank_col(i) = add_universal_rank(current_data{1,"mean_waveform_rep_wire_1"}{1},sliced_grades{i},size(current_data{1,"timestamps"}{1},1),presorted_table,choose_better_nn, presorted_grade_rows, current_data{1,"timestamps"}{1},config);
    %                       add_universal_rank(current_data_waveform,                 current_data_grades,current_data_size,                        presorted_table,choose_better_nn, presorted_grade_rows,current_ts,config)
    print_status_iter_message("train_accuracy_cat_prediction_nn_with_grades_and_universal_rank.m",i,size(blind_pass_table,1));
end
blind_pass_table.("rank") =estimated_rank_col; 

%    data_for_nn = [grades_array(:,:),...
        % all_mean_waveforms,...
        % blind_pass_table{:,"rank"}./100,...
        % blind_pass_table{:,"grades_pred"},...
        % blind_pass_table{:,"mean_wave_pred"},...
        % blind_pass_table{:,"Z Score"},...
        % under_unit_predictor,...
        % size_col,...
        % accuracy_cat_pred,...
        % ];


sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
for i=1:size(sliced_bp_table)
    current_data = sliced_bp_table{1};
    mean_waveform_var_names = contains(current_data.Properties.VariableNames,"mean_waveform_rep_wire");
    all_mean_waveforms = cell2mat(current_data{:,mean_waveform_var_names});

    grades = sliced_grades{i};
    cluster_size = size(current_data{1,"timestamps"}{1},1);


    %get the output of the 4 accuracy cats neural net
    nn_data_for_4_acc_cats = [grades,all_mean_waveforms,current_data{1,"rank"}./100];
    nn_pred_for_4_acc_cats = predict(nn_4_accuracy_cats,nn_data_for_4_acc_cats);
    [~,class] = max(nn_pred_for_4_acc_cats);
    class = class-1;

    nn_data = [grades,...
        all_mean_waveforms(301:end),...
        current_data{1,"grades_pred"},...
        class];

    nn_data =rescale(nn_data,-1,1,"InputMin",col_min([1:18,319:618,620,625]),"InputMax",col_max([1:18,319:618,620,625]));

    class_pred = predict(nn,nn_data);
    [~,max_class_idx] = max(class_pred);
    super_prediction(i) = max_class_idx-1;
end
blind_pass_table.("super_pred") = super_prediction;
end