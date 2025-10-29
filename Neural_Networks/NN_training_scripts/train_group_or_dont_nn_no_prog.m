function [] = train_group_or_dont_nn_no_prog(varargin)
%we'll use no curriculum learning at all

%the goal of this function is to train the neural network to identify which
%clusters found by the algorithm represent the same underlying neuron and


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
dir_to_save_results_to = fullfile(parent_save_dir,"group_or_dont_no_curriculum");
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
%blind_pass_table.og_index = (1:size(blind_pass_table,1)).';
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

%now we'll define a single neural network architecture which we'll hope can
%generalize
%200=num neurons per layer
%21 = num layers
%2 = number of classes
%4403 = number of features in assembled data
layers_of_net = dynamically_create_layers_for_nn(4403,200,21,2);

%now use a for loop to navigate through the progressively noisier recordings
cd(dir_to_save_results_to);
inject_later = []; %used to preserve a subset of the easier examples in order to inject into training of harder examples
%in an effort to prevent later curriculum learning from
%erasing early curriculum learning

%there's a practically infinit number of comarisons that can be made so we
%have to specify how many we'll realistically generate for training as
%computing the overlap feature can be very expensive
%0 = not groupable AKA do not represent the same underlying neuron
%1 = is groupable AKAK does represent the same underlying neuron
number_of_comparisons_per_class = 10000;


current_noise_levels = blind_pass_table;

%get all possible comparisons of the current noise levels
all_comparisons = nchoosek(1:size(current_noise_levels,1),2);

%get the class of every row of comparisons
is_same_neuron = current_noise_levels{all_comparisons(:,1),"Max_Overlap_Unit"} ==current_noise_levels{all_comparisons(:,2),"Max_Overlap_Unit"} & current_noise_levels{all_comparisons(:,1),"recording_name"} ==current_noise_levels{all_comparisons(:,2),"recording_name"};

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
list_of_features_to_add = ["mean_waveform_rep_wire_1","mean_waveform_rep_wire_2","histogram 1","histogram 2","size"];
assembled_data = assemble_data_for_neural_net(list_of_features_to_add,current_noise_levels,config);

%now get the rows of assembled data that represent the left and
%right cluster
left_clust_data = cellfun(@(x) x(current_comparisons_idxs(:,1),:),assembled_data,'UniformOutput',false);
left_clust_data = cell2mat(left_clust_data);
right_clust_data = cellfun(@(x) x(current_comparisons_idxs(:,2),:),assembled_data,'UniformOutput',false);
right_clust_data = cell2mat(right_clust_data);

%calculate the overlap for all the comparisons
overlap_array = zeros(size(current_comparisons_idxs,2),1);
current_noise_levels_parallel = parallel.pool.Constant(current_noise_levels);
current_comparisons_idxs_parallel = parallel.pool.Constant(current_comparisons_idxs);
config_parallel = parallel.pool.Constant(config);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = size(current_comparisons_idxs,1);
print_status_bar(num_iterations,"getting overlap for mixed");
if ~isfile("mixed_overlap.mat")
    for j=1:size(current_comparisons_idxs,1)
        cluster_1_ts = current_noise_levels_parallel.Value{current_comparisons_idxs_parallel.Value(j,1),"timestamps"}{1};
        cluster_2_ts = current_noise_levels_parallel.Value{current_comparisons_idxs_parallel.Value(j,2),"timestamps"}{1};
        [overlap_array(j),~,~] =find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config_parallel.Value.TIME_DELTA);
        send(q,[]);
    end
    par_save("mixed_overlap.mat",overlap_array);
else
    overlap_array = importdata("mixed_overlap.mat");
end

%we scale up overlap because it will be a very important feature, but
%it is naturally between 0-1 so by scaling it up we ensure it doesn't
%get missed
overlap_array = overlap_array * 100;

%now combine the overlap features and true classes of the data
all_nn_data = [left_clust_data,right_clust_data,overlap_array,[zeros(number_of_comparisons_per_class,1);ones(number_of_comparisons_per_class,1)]];

%flip the clusters in order to ensure the neural network doesn't learn
%one side too much
all_nn_data = [right_clust_data,left_clust_data,overlap_array,[zeros(number_of_comparisons_per_class,1);ones(number_of_comparisons_per_class,1)];all_nn_data];
%shuffle the data
all_nn_data = equalize_classes(all_nn_data);

%print the ratio of are same neuron vs not same neuron
disp("# Is same / # is not same")
fprintf("%i / %i\n",sum(all_nn_data(:,end)==1),sum(all_nn_data(:,end)==0))

%now we can train the neural network
[accuracy,net] = train_assembled_network_(all_nn_data,layers_of_net,64);
% layers_of_net = net.Layers;

%print out a statement to reflect accuracy
fprintf("Accuracy: %.2f for recording %s with level %i",accuracy*100,unique_recordings(i));

%save the set in case it fails at any point so we can pick it back
%up
par_save(sprintf("Accuracy %.2f for recording %s with level.mat",accuracy,unique_recordings(i)),net)
end

