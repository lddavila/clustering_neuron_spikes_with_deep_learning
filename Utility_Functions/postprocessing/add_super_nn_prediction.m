function [blind_pass_table] = add_super_nn_prediction(blind_pass_table,config)
nn_struct = importdata(config.FP_TO_super_nn);
nn = nn_struct.net();
% features_to_use = nn_struct.feature_names{1};
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
super_prediction = nan(size(sliced_bp_table,1),1);
under_unit_predictor_struct = importdata(config.FP_TO_Multi_under_units_predicting_nn);
under_unit_predictor = under_unit_predictor_struct.net;


load("C:\Users\ldd77\OneDrive\Desktop\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\rescale_params.mat");

four_acc_cat_predicting_nn = importdata(config.FP_TO_4_accuracy_cats_predictor);
nn_4_accuracy_cats = four_acc_cat_predicting_nn.net;


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
for i=1:size(sliced_bp_table)
    current_data = sliced_bp_table{1};
    mean_waveform_var_names = contains(current_data.Properties.VariableNames,"mean_waveform_rep_wire");
    all_mean_waveforms = cell2mat(current_data{:,mean_waveform_var_names});
    
    grades = current_data{1,"grades"}{1};
    grades = cell2mat(grades(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST));
    cluster_size = size(current_data{1,"timestamps"}{1},1);
    data_for_under_unit_predictor = [grades,all_mean_waveforms(1:150)];

    %get the output of the under unit neural net
    under_unit_prediction_probs = predict(under_unit_predictor,data_for_under_unit_predictor);
    [~,under_unit_class] = max(under_unit_prediction_probs);
    under_unit_class = under_unit_class-1;

    %get the output of the 4 accuracy cats neural net
    nn_data_for_4_acc_cats = [grades,all_mean_waveforms,current_data{1,"rank"}./100];
    nn_pred_for_4_acc_cats = predict(nn_4_accuracy_cats,nn_data_for_4_acc_cats);
    [~,class] = max(nn_pred_for_4_acc_cats);
    class = class-1;

    nn_data = [grades,...
        all_mean_waveforms,...
        current_data{1,"rank"},...
        current_data{1,"grades_pred"},...
        current_data{1,"mean_wave_pred"},...
        current_data{1,"Z Score"},...
        under_unit_class,...
        cluster_size,...
        class];

    nn_data =rescale(nn_data,-1,1,"InputMin",col_min,"InputMax",col_max);

    class_pred = predict(nn,nn_data);
    [~,max_class_idx] = max(class_pred);
    super_prediction(i) = max_class_idx-1;
end
blind_pass_table.("super_pred") = super_prediction;
end