function [] = switch_case_training_with_distance_and_z_score(varargin)
%differs from train_group_or_dont_nn_with_progressive_difficulty.m & train_group_or_dont_nn_with_prog_diff_and_no_grades.m because
%this model does not include grades nor does it use overlap percentage as
%part of the curriculum
%the goal is to test whether or not grades are actually a hinderance to the
%grouping process instead of helpful

%The curriculum based here will be based only on the noise level of the original recording
%this does not add difficulty based on overlap to the curriculum

%the goal of this function is to train the neural network to identify which
%clusters found by the algorithm represent the same underlying neuron and
%train it on progressively harder datasets
%where we define harder as how noisy the simulated data set was

%get the probe map
[probe_graph,x,y] = get_graph_rep_of_probe_map;

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
dir_to_save_results_to = fullfile(parent_save_dir,"switch_case_z_score_normalized_no_histograms_with_shtst_path");
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

%set the random seed for reproducable results
rng("default")
disp("Finished setting seed")



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

    %now we'll define a single neural network architecture which we'll hope
    %can generalize to all data that exists at the current noise level
    %20 = num neurons per layer
    %21 = num layers
    %2 = number of classes
    %4403 = number of features in assembled data
    layers_of_net = dynamically_create_layers_for_nn(604,20,21,2);

    
    current_noise_levels = partitioned_mixed{i,1};

    %get all possible comparisons of the current noise levels
    all_comparisons = nchoosek(1:size(current_noise_levels,1),2);

    %get the class of every row of comparisons
    is_same_neuron = current_noise_levels{all_comparisons(:,1),"Max_Overlap_Unit"} ==current_noise_levels{all_comparisons(:,2),"Max_Overlap_Unit"};

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
    assembled_data = assemble_data_for_neural_net(list_of_features_to_add,current_noise_levels,config);

    %now get the rows of assembled data that represent the left and
    %right cluster
    left_clust_data = cellfun(@(x) x(current_comparisons_idxs(:,1),:),assembled_data,'UniformOutput',false);
    left_clust_data = cell2mat(left_clust_data);
    right_clust_data = cellfun(@(x) x(current_comparisons_idxs(:,2),:),assembled_data,'UniformOutput',false);
    right_clust_data = cell2mat(right_clust_data);

     %now get the average shortest distance between the 2 channels
    avg_shortest_path = get_shortest_path_feature(current_noise_levels,current_comparisons_idxs,1,probe_graph,x,y);

    %calculate the overlap for all the comparisons
    overlap_array = zeros(size(current_comparisons_idxs,1),1);
    current_noise_levels_parallel = parallel.pool.Constant(current_noise_levels);
    current_comparisons_idxs_parallel = parallel.pool.Constant(current_comparisons_idxs);
    config_parallel = parallel.pool.Constant(config);
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    num_iterations = size(current_comparisons_idxs,1);
    print_status_bar(num_iterations,"getting overlap for recording:"+unique_recordings(i));
    if ~isfile("overlap_col_for_"+unique_recordings(i)+".mat")
        parfor j=1:size(current_comparisons_idxs,1)
            cluster_1_ts = current_noise_levels_parallel.Value{current_comparisons_idxs_parallel.Value(j,1),"timestamps"}{1};
            cluster_2_ts = current_noise_levels_parallel.Value{current_comparisons_idxs_parallel.Value(j,2),"timestamps"}{1};
            [overlap_array(j),~,~] =find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config_parallel.Value.TIME_DELTA);
            send(q,[]);
        end
        par_save("overlap_col_for_"+unique_recordings(i)+".mat",overlap_array);
    else
        overlap_array = importdata("overlap_col_for_"+unique_recordings(i)+".mat");
    end

    %now combine the overlap features and true classes of the data
    all_nn_data = [left_clust_data,right_clust_data,overlap_array,avg_shortest_path,[zeros(number_of_comparisons_per_class,1);ones(number_of_comparisons_per_class,1)]];

    %flip the clusters in order to ensure the neural network doesn't learn
    %one side too much
    all_nn_data = [right_clust_data,left_clust_data,overlap_array,avg_shortest_path,[zeros(number_of_comparisons_per_class,1);ones(number_of_comparisons_per_class,1)];all_nn_data];
    %shuffle the data
    all_nn_data = equalize_classes(all_nn_data);

    %now perform z-score normalization on the data
    [X_norm, cell_array_of_mus{i}, cell_array_of_sig{i}] = safe_zscore_normalizer(all_nn_data(:,1:end-1));


    %print the ratio of are same neuron vs not same neuron
    disp("# Is same / # is not same")
    fprintf("%i / %i\n",sum(all_nn_data(:,end)==1),sum(all_nn_data(:,end)==0))

    %now we can train the neural network
    [accuracy,net] = train_assembled_network_([X_norm,all_nn_data(:,end)],layers_of_net,64);
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
    current_noise_levels = partitioned_mixed{i,2};

    %get all possible comparisons of the current noise levels
    all_comparisons = nchoosek(1:size(current_noise_levels,1),2);

    %get the class of every row of comparisons
    is_same_neuron = current_noise_levels{all_comparisons(:,1),"Max_Overlap_Unit"} ==current_noise_levels{all_comparisons(:,2),"Max_Overlap_Unit"};

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
    list_of_features_to_add = ["mean_waveform_rep_wire_1","mean_waveform_rep_wire_2","mean_waveform_rep_wire_3","mean_waveform_rep_wire_4","histogram 1","histogram 2", "histogram 3","histogram 4","size"];
    assembled_data = assemble_data_for_neural_net(list_of_features_to_add,current_noise_levels,config);

    %now get the rows of assembled data that represent the left and
    %right cluster
    left_clust_data = cellfun(@(x) x(current_comparisons_idxs(:,1),:),assembled_data,'UniformOutput',false);
    left_clust_data = cell2mat(left_clust_data);
    right_clust_data = cellfun(@(x) x(current_comparisons_idxs(:,2),:),assembled_data,'UniformOutput',false);
    right_clust_data = cell2mat(right_clust_data);

    %now get the average shortest distance between the 2 channels
    avg_shortest_path = get_shortest_path_feature(current_noise_levels,current_comparisons_idxs,1,probe_graph,x,y);

    %calculate the overlap for all the comparisons
    overlap_array = zeros(size(current_comparisons_idxs,2),1);
    current_noise_levels_parallel = parallel.pool.Constant(current_noise_levels);
    current_comparisons_idxs_parallel = parallel.pool.Constant(current_comparisons_idxs);
    config_parallel = parallel.pool.Constant(config);
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    num_iterations = size(current_comparisons_idxs,1);
    print_status_bar(num_iterations,"getting overlap for recording:"+unique_recordings(i));
    if ~isfile("overlap_col_for_"+unique_recordings(i)+".mat")
        parfor j=1:size(current_comparisons_idxs,1)
            cluster_1_ts = current_noise_levels_parallel.Value{current_comparisons_idxs_parallel.Value(j,1),"timestamps"}{1};
            cluster_2_ts = current_noise_levels_parallel.Value{current_comparisons_idxs_parallel.Value(j,2),"timestamps"}{1};
            [overlap_array(j),~,~] =find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config_parallel.Value.TIME_DELTA);
            send(q,[]);
        end
        par_save("overlap_col_for_"+unique_recordings(i)+".mat",overlap_array);
    else
        overlap_array = importdata("overlap_col_for_"+unique_recordings(i)+".mat");
    end


    %now combine the overlap features and true classes of the data
    all_nn_data = [left_clust_data,right_clust_data,overlap_array,avg_shortest_path,[zeros(number_of_comparisons_per_class,1);ones(number_of_comparisons_per_class,1)]];

    %flip the clusters in order to ensure the neural network doesn't learn
    %one side too much
    all_nn_data = [right_clust_data,left_clust_data,overlap_array,avg_shortest_path,[zeros(number_of_comparisons_per_class,1);ones(number_of_comparisons_per_class,1)];all_nn_data];
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