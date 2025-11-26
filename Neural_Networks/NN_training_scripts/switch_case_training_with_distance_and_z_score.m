function [] = switch_case_training_with_distance_and_z_score(varargin)
%tries to mind a general method to determine if the 2 clusters are the
%same or not for clusters that are on the same noise level
%-has z score normalization 
%-has the average path length between channels feature (as calculated by a
%graph which represents the probe map)

%get the graph which we'll calculate shortest distance off of
[G,x,y] = get_graph_rep_of_probe_map();

%ensure that you're on the correct fp while running the scipt
current_script_file_path = mfilename('fullpath');
[current_script_dir,~,~] = fileparts(current_script_file_path);
cd(current_script_dir);

%put all files on the path
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);


%get the config
config = spikesort_config();
parent_save_dir = config.parent_save_dir;
disp("Finished Loading Config")

%only for alexander's broken hpc account
if contains(config.base_file_path,"afriedman")
    parpool('local_40', 40);
end

%create a directory where the results will be saved
dir_to_save_results_to = fullfile(parent_save_dir,"switch_case_z_score_normalized_no_histograms_extra_part_and_pth_fixed_test");
if ~exist(dir_to_save_results_to,"dir")
    dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_results_to);
end
disp("Finished Creating directory")


%now we load the master training blind pass table which has various
%examples with various noise levels and accuracy
if length(varargin)<1
    blind_pass_table = importdata(config.FP_TO_MASTER_TRAINING_BP_TABLE);
else
    blind_pass_table = varargin{1};
end

%partition the tables by the underlying neurons to prevent data leakage
partitioned_mixed = partition_bp_tables(blind_pass_table);
disp("Finished loading blind pass table")


%now extract how many recordings and thus noise levels are in the blind
%pass table
unique_recordings = unique(blind_pass_table{:,"recording_name"});
unique_recordings_split = split(unique_recordings,"_");
noise_levels = str2double(unique_recordings_split(:,1));
[noise_levels,indexes_of_sorted_noise_levels] = sort(noise_levels,'ascend');
unique_recordings = unique_recordings(indexes_of_sorted_noise_levels);




%now use a for loop to navigate through the progressively noisier recordings
cd(dir_to_save_results_to);
%in an effort to prevent later curriculum learning from
%erasing early curriculum learning

%there's a practically infinit number of comarisons that can be made so we
%have to specify how many we'll realistically generate for training as
%computing the overlap feature can be very expensive
%0 = not groupable AKA do not represent the same underlying neuron
%1 = is groupable AKAK does represent the same underlying neuron
number_of_comparisons_per_class = 10000;
cell_array_of_trained_nets = cell(1,length(noise_levels));
cell_array_of_mus = cell(1,length(noise_levels));
cell_array_of_sig = cell(1,length(noise_levels)); 
for i=1:length(noise_levels)

    %set the random seed for reproducable results
    rng("default")
    disp("Finished setting seed")

    
    current_noise_level_data = partitioned_mixed{i,1};

    %paritition the data again in order to ensure that validation doesn't
    %rely on memorizing comparisons for mergability
    partitioned_noise_level_data = partition_bp_tables(current_noise_level_data);

    current_noise_level_data = partitioned_noise_level_data{1,1};
    val_noise_level_data = partitioned_noise_level_data{1,2};

    %get all possible comparisons of the current noise levels
    all_comparisons = nchoosek(1:size(current_noise_level_data,1),2);
    all_val_comparisons = nchoosek(1:size(val_noise_level_data,1),2);


    %get the class of every row of comparisons
    is_same_neuron = current_noise_level_data{all_comparisons(:,1),"Max_Overlap_Unit"} == current_noise_level_data{all_comparisons(:,2),"Max_Overlap_Unit"};
    is_same_neuron_val = val_noise_level_data{all_val_comparisons(:,1),"Max_Overlap_Unit"} == val_noise_level_data{all_val_comparisons(:,2),"Max_Overlap_Unit"};

    %randomly sample each class specified in
    %number_of_comparisons_per_class
    comparisons_with_class_1= find(is_same_neuron);
    comparisons_with_class_0 = find(~is_same_neuron);
    val_class_1_comparisons = find(is_same_neuron_val);
    val_class_0_comparisons = find(~is_same_neuron_val);

    randomly_selected_class_1 = randperm(length(comparisons_with_class_1),number_of_comparisons_per_class);
    randomly_selected_class_0 = randperm(length(comparisons_with_class_0),number_of_comparisons_per_class);

    randomly_selected_class_1_val = randperm(length(val_class_1_comparisons),number_of_comparisons_per_class);
    randomly_selected_class_0_val = randperm(length(val_class_0_comparisons),number_of_comparisons_per_class);


    current_comparisons_idxs = [all_comparisons(randomly_selected_class_0,:);all_comparisons(randomly_selected_class_1,:)];
    current_val_comparison_idxs = [all_val_comparisons(randomly_selected_class_0_val,:);all_val_comparisons(randomly_selected_class_1_val,:)];




    list_of_features_to_add = ["mean_waveform_rep_wire_1","mean_waveform_rep_wire_2","size"];
    assembled_data = assemble_data_for_neural_net(list_of_features_to_add,current_noise_level_data,config);
    assembled_val_data = assemble_data_for_neural_net(list_of_features_to_add,val_noise_level_data,config);

    %now get the rows of assembled data that represent the left and
    %right cluster
    left_clust_data = cellfun(@(x) x(current_comparisons_idxs(:,1),:),assembled_data,'UniformOutput',false);
    left_clust_data = cell2mat(left_clust_data);
    right_clust_data = cellfun(@(x) x(current_comparisons_idxs(:,2),:),assembled_data,'UniformOutput',false);
    right_clust_data = cell2mat(right_clust_data);

    left_clust_data_val = cellfun(@(x) x(current_val_comparison_idxs(:,1),:),assembled_val_data,'UniformOutput',false);
    left_clust_data_val = cell2mat(left_clust_data_val);
    right_clust_data_val = cellfun(@(x) x(current_val_comparison_idxs(:,2),:),assembled_val_data,'UniformOutput',false);
    right_clust_data_val = cell2mat(right_clust_data_val);

    %calculate the overlap for all the comparisons
    overlap_array = zeros(size(current_comparisons_idxs,1),1);
    current_noise_levels_parallel = parallel.pool.Constant(current_noise_level_data);
    current_comparisons_idxs_parallel = parallel.pool.Constant(current_comparisons_idxs);
    config_parallel = parallel.pool.Constant(config);
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    num_iterations = size(current_comparisons_idxs,1);
    print_status_bar(num_iterations,"getting overlap for recording:"+unique_recordings(i));
    if ~isfile("overlap_col_for_"+unique_recordings(i)+".mat")
        for j=1:size(current_comparisons_idxs,1)
            cluster_1_ts = current_noise_levels_parallel.Value{current_comparisons_idxs_parallel.Value(j,1),"timestamps"}{1};
            cluster_2_ts = current_noise_levels_parallel.Value{current_comparisons_idxs_parallel.Value(j,2),"timestamps"}{1};
            [overlap_array(j),~,~] =find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config_parallel.Value.TIME_DELTA);
            send(q,[]);
        end
        par_save("overlap_col_for_"+unique_recordings(i)+".mat",overlap_array);
    else
        overlap_array = importdata("overlap_col_for_"+unique_recordings(i)+".mat");
    end
    

   

    %do the same for the validation data 
    overlap_array_val = zeros(size(current_val_comparison_idxs,1),1);
    current_noise_levels_parallel = parallel.pool.Constant(val_noise_level_data);
    current_comparisons_idxs_parallel = parallel.pool.Constant(current_val_comparison_idxs);
    config_parallel = parallel.pool.Constant(config);
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    num_iterations = size(current_comparisons_idxs,1);
    print_status_bar(num_iterations,"getting val overlap for recording:"+unique_recordings(i));
    if ~isfile("val_overlap_col_for_"+unique_recordings(i)+".mat")
        for j=1:size(current_val_comparison_idxs,1)
            cluster_1_ts = current_noise_levels_parallel.Value{current_comparisons_idxs_parallel.Value(j,1),"timestamps"}{1};
            cluster_2_ts = current_noise_levels_parallel.Value{current_comparisons_idxs_parallel.Value(j,2),"timestamps"}{1};
            [overlap_array_val(j),~,~] =find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config_parallel.Value.TIME_DELTA);
            send(q,[]);
        end
        par_save("val_overlap_col_for_"+unique_recordings(i)+".mat",overlap_array_val);
    else
        overlap_array_val = importdata("val_overlap_col_for_"+unique_recordings(i)+".mat");
    end

    %now get the shortest distance feature for the training comparisons
    shortest_dist_col = get_shortest_path_feature(current_noise_level_data,current_comparisons_idxs,0,G,x,y);

    %now get the shortest distance feature for the validation set
    shortest_dist_val = get_shortest_path_feature(val_noise_level_data,current_val_comparison_idxs,0,G,x,y);

    %now combine the overlap features and true classes of the data
    all_nn_data = [left_clust_data,right_clust_data,overlap_array,shortest_dist_col,[zeros(number_of_comparisons_per_class,1);ones(number_of_comparisons_per_class,1)]];
    all_val_nn_data = [left_clust_data_val,right_clust_data_val,overlap_array_val,shortest_dist_val,[zeros(number_of_comparisons_per_class,1);ones(number_of_comparisons_per_class,1)]];

    %flip the clusters in order to ensure the neural network doesn't learn
    %one side too much
    all_nn_data = [right_clust_data,left_clust_data,overlap_array,shortest_dist_col,[zeros(number_of_comparisons_per_class,1);ones(number_of_comparisons_per_class,1)];all_nn_data];
    all_val_nn_data = [right_clust_data_val,left_clust_data_val,overlap_array_val,shortest_dist_val,[zeros(number_of_comparisons_per_class,1);ones(number_of_comparisons_per_class,1)];all_val_nn_data];

    %shuffle the data
    all_nn_data = equalize_classes(all_nn_data);
    all_val_nn_data = equalize_classes(all_val_nn_data);

    %now perform z-score normalization on the data
    [X_norm, cell_array_of_mus{i}, cell_array_of_sig{i}] = safe_zscore_normalizer(all_nn_data(:,1:end-1));
    
    %normalize the validation data based on the data from the training set
    X_Val = all_val_nn_data(:,1:end-1);
    X_Val = (X_Val - cell_array_of_mus{i}) ./ cell_array_of_sig{i};
    X_Val(:, cell_array_of_sig{i} == 0) = 0;


    %print the ratio of are same neuron vs not same neuron
    disp("# Is same / # is not same")
    fprintf("%i / %i\n",sum(all_nn_data(:,end)==1),sum(all_nn_data(:,end)==0))

    %now we'll define a single neural network architecture 
    %20 = num neurons per layer
    %21 = num layers
    %2 = number of classes
    %size(X_norm,2) = number of features in assembled data
    layers_of_net = dynamically_create_layers_for_nn(size(X_norm,2),20,21,2);

    %now we can train the neural network
    [accuracy,net] = test_nn_on_incremental_challenging([X_norm,all_nn_data(:,end)],[X_Val,all_val_nn_data(:,end)],layers_of_net,64);
    cell_array_of_trained_nets{i} = net;

    %print out a statement to reflect accuracy
    fprintf("Accuracy: %.2f for recording %s with level %i",accuracy*100,unique_recordings(i));

    %save the set in case it fails at any point so we can pick it back
    %up

    net_struct = struct();
    net_struct.net = net;
    net_struct.mean= cell_array_of_mus{i};
    net_struct.std = cell_array_of_sig{i};
    par_save(sprintf("Accuracy %.2f for recording %s with level.mat",accuracy,unique_recordings(i)),net_struct)
end

%now we can validate each of the neural networks on comparisons at similar
%noise levels that it has yet to see the underlying neuron for

for i=1:length(noise_levels)
    current_noise_level_data = partitioned_mixed{i,2};

    %get all possible comparisons of the current noise levels
    all_comparisons = nchoosek(1:size(current_noise_level_data,1),2);

    %get the class of every row of comparisons
    is_same_neuron = current_noise_level_data{all_comparisons(:,1),"Max_Overlap_Unit"} ==current_noise_level_data{all_comparisons(:,2),"Max_Overlap_Unit"};

    %randomly sample each class specified in
    %number_of_comparisons_per_class
    comparisons_with_class_1= find(is_same_neuron);
    comparisons_with_class_0 = find(~is_same_neuron);

    randomly_selected_class_1 = randperm(length(comparisons_with_class_1),number_of_comparisons_per_class);
    randomly_selected_class_0 = randperm(length(comparisons_with_class_0),number_of_comparisons_per_class);

    current_comparisons_idxs = [all_comparisons(randomly_selected_class_0,:);all_comparisons(randomly_selected_class_1,:)];


    %get the NN data out of current_noise_levels
    %we won't normalize here because the raw values have significant meaning
    %i.e. microvolts and bin count
    list_of_features_to_add = ["mean_waveform_rep_wire_1","mean_waveform_rep_wire_2","size"];
    assembled_data = assemble_data_for_neural_net(list_of_features_to_add,current_noise_level_data,config);

    %now get the rows of assembled data that represent the left and
    %right cluster
    left_clust_data = cellfun(@(x) x(current_comparisons_idxs(:,1),:),assembled_data,'UniformOutput',false);
    left_clust_data = cell2mat(left_clust_data);
    right_clust_data = cellfun(@(x) x(current_comparisons_idxs(:,2),:),assembled_data,'UniformOutput',false);
    right_clust_data = cell2mat(right_clust_data);

    %now get the shortest distance feature for the test data
    shortest_dist_val = get_shortest_path_feature(current_noise_level_data,current_comparisons_idxs,0,G,x,y);

    %calculate the overlap for all the comparisons
    overlap_array = zeros(size(current_comparisons_idxs,1),1);
    current_noise_levels_parallel = parallel.pool.Constant(current_noise_level_data);
    current_comparisons_idxs_parallel = parallel.pool.Constant(current_comparisons_idxs);
    config_parallel = parallel.pool.Constant(config);
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    num_iterations = size(current_comparisons_idxs,1);
    print_status_bar(num_iterations,"getting overlap for recording:"+unique_recordings(i));
    if ~isfile("test_overlap_col_for_"+unique_recordings(i)+".mat")
        parfor j=1:size(current_comparisons_idxs,1)
            cluster_1_ts = current_noise_levels_parallel.Value{current_comparisons_idxs_parallel.Value(j,1),"timestamps"}{1};
            cluster_2_ts = current_noise_levels_parallel.Value{current_comparisons_idxs_parallel.Value(j,2),"timestamps"}{1};
            [overlap_array(j),~,~] =find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config_parallel.Value.TIME_DELTA);
            send(q,[]);
        end
        par_save("test_overlap_col_for_"+unique_recordings(i)+".mat",overlap_array);
    else
        overlap_array = importdata("test_overlap_col_for_"+unique_recordings(i)+".mat");
    end


    %now combine the overlap features and true classes of the data
    all_nn_data = [left_clust_data,right_clust_data,overlap_array,shortest_dist_val,[zeros(number_of_comparisons_per_class,1);ones(number_of_comparisons_per_class,1)]];

    %flip the clusters in order to ensure the neural network doesn't learn
    %one side too much
    all_nn_data = [right_clust_data,left_clust_data,overlap_array,shortest_dist_val,[zeros(number_of_comparisons_per_class,1);ones(number_of_comparisons_per_class,1)];all_nn_data];
    %shuffle the data
    all_nn_data = equalize_classes(all_nn_data);

    %now normalize using the training normalization
    %DO NOT RECOMPUTE
    X_Test = all_nn_data(:,1:end-1);
    X_Test = (X_Test - cell_array_of_mus{i}) ./ cell_array_of_sig{i};
    X_Test(:, cell_array_of_sig{i} == 0) = 0;

    %print the ratio of are same neuron vs not same neuron
    disp("# Is same / # is not same")
    fprintf("%i / %i\n",sum(all_nn_data(:,end)==1),sum(all_nn_data(:,end)==0))

    %now test the neural network
    net = cell_array_of_trained_nets{i};

    scores = predict(net,X_Test);
    [~,YPred] = max(scores,[],2);
    YPred = YPred-1;

    accuracy = sum(YPred==all_nn_data(:,end))/size(all_nn_data,1);

    %print out a statement to reflect accuracy
    fprintf("Accuracy: %.2f for recording %s with level %i",accuracy*100,unique_recordings(i));
end

end