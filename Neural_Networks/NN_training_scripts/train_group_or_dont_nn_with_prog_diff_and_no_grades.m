function [] = train_group_or_dont_nn_with_prog_diff_and_no_grades(varargin)

%differs from train_group_or_dont_nn_with_progressive_difficulty.m because
%this model does not include grades
%the goal is to test whether or not grades are actually a hinderance to the
%grouping process instead of helpful

%The curriculum based here will depend not only on the overlap between
%clusters but also the noise level of the original recording

%the goal of this function is to train the neural network to identify which
%clusters found by the algorithm represent the same underlying neuron and
%train it on progressively harder datasets
%where we define harder as how much overlap in timestamps any 2 clusters may have
%obiously it is very easy to merge 2 clusters that have a high degree of
%overlap but the key in solving the problem is to identify pairs which have
%high overlap but don't represent the same underlying neuron or have a low
%overlap but do represent the same underlying neuron
delete(gcp('nocreate'));
%ensure that you're on the correct fp while running the scipt
current_script_file_path = mfilename('fullpath');
[current_script_dir,~,~] = fileparts(current_script_file_path);
cd(current_script_dir);


%we know already that it can easily choose better with practically 100%
%accuracy when the accuracy differences are large

%we also know that they fail when the accuracy differences are closer
%together

%so hopefully multiple training phases with smaller and smaller accuracy
%decreases will improve overall training

%first let's put all files on the path
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);

%now we must get the config
config = spikesort_config();
parent_save_dir = config.parent_save_dir;
disp("Finished Loading Config")

if contains(config.base_file_path,"afriedman")
    parpool('local_40', 40);
end

%create a directory where the results will be saved
dir_to_save_results_to = fullfile(parent_save_dir,"group_or_dont_incremental_no_grades_expanded");
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

%set the random seed for repeatable results
rng("default")
disp("Finished setting seed")

%now we'll define a single neural network architecture which we'll hope can
%generalize
%20=num neurons per layer
%21 = num layers
%2 = number of classes
%4403 = number of features in assembled data
layers_of_net = dynamically_create_layers_for_nn(4403,20,21,2);

%now use a for loop to navigate through the progressively noisier recordings
extracted_rows = [];
cd(dir_to_save_results_to);
inject_later = []; %used to preserve a subset of the easier examples in order to inject into training of harder examples
                   %in an effort to prevent later curriculum learning from
                   %erasing early curriculum learning
for i=1:length(noise_levels)
    current_noise_levels = blind_pass_table(blind_pass_table{:,"recording_name"}==unique_recordings(i),:);

    %within the current recording we'll want to first see how many times
    %each unit unit in the underlying recordings appear
    groupcounts_of_units = groupcounts(current_noise_levels,"Max_Overlap_Unit");

    %the number of rows in groupcounts of units coordinates to how many
    %units actually appeared in the blind pass

    %we'll want to ensure that every unit it roughly equally presented
    %this will ensure during training that there's no bias which will
    %poison the training

    %first we'll randomly extract 30% of all units from the blind pass to
    %ensure that when we validate it is on completely unknown data
    number_of_units_to_extract = round(size(groupcounts_of_units,1)*0.3);


    units_to_extract = randperm(size(groupcounts_of_units,1),number_of_units_to_extract);
    units_to_remain = setdiff(1:size(groupcounts_of_units,1),units_to_extract);

    %now add the units to extract to the extracted rows
    extracted_rows = [extracted_rows;current_noise_levels(any(current_noise_levels{:,"Max_Overlap_Unit"}==units_to_extract,2),:)];

    %now take the remaining units into their own table
    training_rows = current_noise_levels(any(current_noise_levels{:,"Max_Overlap_Unit"}==units_to_remain,2),:);

    %(roughly) equalize cluster appearences in training rows
    groupcounts_of_training_rows = groupcounts_of_units(any(groupcounts_of_units{:,"Max_Overlap_Unit"}==units_to_remain,2),:);
    min_number_of_cluster_appearences = 15;

    equalized_training_rows = [];
    for k=1:size(groupcounts_of_training_rows,1)
        all_examples_of_current_unit = find(training_rows{:,"Max_Overlap_Unit"} == groupcounts_of_training_rows{k,"Max_Overlap_Unit"});
        indexes_of_randomly_sampled_reps_of_current_unit = randperm(length(all_examples_of_current_unit),min([min_number_of_cluster_appearences,length(all_examples_of_current_unit)]));
        equalized_training_rows = [equalized_training_rows;training_rows(all_examples_of_current_unit(indexes_of_randomly_sampled_reps_of_current_unit),:)];
    end

    %now we'll extract some desired data from the equalized_training_rows
    %we won't normalize here because the raw values have significant meaning
    %i.e. microvolts and bin count
    list_of_features_to_add = ["mean_waveform_rep_wire_1","mean_waveform_rep_wire_2","mean_waveform_rep_wire_3","mean_waveform_rep_wire_4","histogram 1","histogram 2", "histogram 3","histogram 4","size"];
    assembled_data = assemble_data_for_neural_net(list_of_features_to_add,equalized_training_rows,config);

    %now get all possible comparisons of the equalized_training_rows
    all_comparisons = nchoosek(1:size(equalized_training_rows,1),2);

    %get the class of every row of comparisons
    is_same_neuron = equalized_training_rows{all_comparisons(:,1),"Max_Overlap_Unit"}==equalized_training_rows{all_comparisons(:,2),"Max_Overlap_Unit"};



    %add the flipped comparisons to the end of comparisons to ensure the NN
    %sees both possible views
    %all_possible_comparisons = [all_possible_comparisons;[all_possible_comparisons(:,1),all_possible_comparisons(:,2)]];

    %now we can calculate the overlap feature betwene all the comparisons
    %overlap between clusters is possibly the most important feature as
    %both because it is very informative of the clusters being the same
    %neuron and because it makes up the second level of our curriculum
    %learning

    overlap_array = zeros(length(all_comparisons),1);
    equalized_training_rows_parallel = parallel.pool.Constant(equalized_training_rows);
    all_comparisons_parallel = parallel.pool.Constant(all_comparisons);
    config_parallel = parallel.pool.Constant(config);
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    num_iterations = size(all_comparisons,1);
    print_status_bar(num_iterations,"getting overlap for recording:"+unique_recordings(i));
    if ~isfile("overlap_col_for_"+unique_recordings(i)+".mat")
        parfor j=1:size(all_comparisons,1)
            cluster_1_ts = equalized_training_rows_parallel.Value{all_comparisons_parallel.Value(j,1),"timestamps"}{1};
            cluster_2_ts = equalized_training_rows_parallel.Value{all_comparisons_parallel.Value(j,2),"timestamps"}{1};
            [overlap_array(j),~,~] =find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs(cluster_1_ts,cluster_2_ts,config_parallel.Value.TIME_DELTA);
            send(q,[]);
        end
        par_save("overlap_col_for_"+unique_recordings(i)+".mat",overlap_array);
    else
        overlap_array = importdata("overlap_col_for_"+unique_recordings(i)+".mat");
    end

    overlap_array = overlap_array * 100;
    %now we'll set up the second part of our curriculum
    %the second level of the curriculum is based upon the amount of overlap
    %between the two comparisons 
    %we'll group the comparisons in terms of their overlap measurement
    %recall overlap is a measurement of
        %# timestamps in common / size of the smaller cluster

        %which is reflective of how much of the smaller cluster exists in
        %the larger cluster
        %the value is between 0-1
        %where 0 is no overlap and 1 is complete overlap

    %they'll be decreasing in overlap by .05
    %this ensures the easier determinations are at the beginning
    %(low difficulty level) and the harder are at the end (higher difficulty level) 
    list_of_magnitudes = 1:-.1:0;
    comparisons_within_overlap_bounds = cell(size(list_of_magnitudes,2),1);
    cell_array_of_true_class_for_comparisons = cell(size(list_of_magnitudes,2),1);
    cell_array_of_overlap_feature = cell(size(list_of_magnitudes,2),1);
    for k=1:length(list_of_magnitudes)-1
        c1 = overlap_array <= list_of_magnitudes(k);
        c2 = overlap_array > list_of_magnitudes(k+1);
        comparisons_within_overlap_bounds{k} = all_comparisons(c1 & c2,:);
        cell_array_of_true_class_for_comparisons{k} = is_same_neuron(c1 & c2);
        cell_array_of_overlap_feature{k} = overlap_array(c1 & c2);
    end

    %now we can use a for loop to cycle through these progressively harder
    %data sets
    for k=1:length(comparisons_within_overlap_bounds)
        current_comparisons_idxs = comparisons_within_overlap_bounds{k};
        if isempty(current_comparisons_idxs)
            continue;
        end
        true_class_for_current_comparions = cell_array_of_true_class_for_comparisons{k};
        overlap_data = cell_array_of_overlap_feature{k};
        if size(current_comparisons_idxs,1)>10000
            current_comparisons_idxs = current_comparisons_idxs(1:10000,:);
            true_class_for_current_comparions = true_class_for_current_comparions(1:10000);
            overlap_data = overlap_data(1:10000);
        end
        %now get the rows of assembled data that represent the left and
        %right cluster
        left_clust_data = cellfun(@(x) x(current_comparisons_idxs(:,1),:),assembled_data,'UniformOutput',false);
        left_clust_data = cell2mat(left_clust_data);
        right_clust_data = cellfun(@(x) x(current_comparisons_idxs(:,2),:),assembled_data,'UniformOutput',false);
        right_clust_data = cell2mat(right_clust_data);

        

        %put all of this data into a single matrix
        all_training_data = [left_clust_data,right_clust_data,overlap_data,true_class_for_current_comparions];
        %below we flip all the left/right data to ensure that the neural
        %network doesn't get too comfortable seeing one cluster on the same
        %side
        all_training_data = [all_training_data;[right_clust_data,left_clust_data,overlap_data,true_class_for_current_comparions]];

        %take some trainig data and preserve it for later training 
        random_eaiser_indexes = randperm(size(all_training_data,1),round(size(all_training_data,1) * 0.20));
        inject_later = [inject_later;all_training_data(random_eaiser_indexes,:)];

        all_training_data = [all_training_data;inject_later];

        %now equalzie the training of both
        all_training_data = equalize_classes(all_training_data);
        

        %print the ratio of are same neuron vs not same neuron
        disp("# Is same / # is not same")
        fprintf("%i / %i\n",sum(all_training_data(:,end)==1),sum(all_training_data(:,end)==0))

        %now we can train the neural network
        [accuracy,net] = train_assembled_network_(all_training_data,layers_of_net,16);
        layers_of_net = net.Layers;
        %print out a statement to reflect accuracy
        fprintf("Accuracy: %.2f for recording %s with level %i difficulty \n",accuracy,unique_recordings(i),k);

        %save the set in case it fails at any point so we can pick it back
        %up
        par_save(sprintf("Accuracy %.2f for recording %s with level %i difficulty.mat",accuracy,unique_recordings(i),k),net)


    end

end






end