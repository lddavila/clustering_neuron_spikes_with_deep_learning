function [] = train_choose_better_cluster_incremental_difficulty(varargin)
%the goal of this function is to train the neural network on progressively
%harder and harder challenges

%first start the parallel pool so we can access the # of available workers
 c = parcluster('local'); 
 num_workers = c.NumWorkers;

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

%create a directory where the results will be saved
dir_to_save_results_to = fullfile(parent_save_dir,"incremental_ch_bttr_nn");
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

%set the random seed for repeatable results
rng("default")
disp("Finished setting seed")

%now we'll extract some desired data from the blind_pass table which will
%be used for training 
list_of_features_to_add = ["mean_waveform_rep_wire_1","mean_waveform_rep_wire_2","mean_waveform_rep_wire_3","mean_waveform_rep_wire_4","histogram 1","histogram 2", "histogram 3","histogram 4","size","grades 2"];
grades_data = assemble_data_for_neural_net(["grades 2"],blind_pass_table,config);
normalized_grades = normalize(grades_data{1});
disp("Finished getting feature data")

%now we'll get all possible comparisons of 2 in the blind pass table
%luckily we will never suffer for lack of number of comparisons
all_comparisons = nchoosek(1:size(blind_pass_table,1),2);
disp("Finished getting all possible comparisons of 2")

%now for each comparison get a boolean vector which tells us if the "left"
%AKA 1st col of all_comparions
%has a higher accuracy
%is_left_better_col = blind_pass_table{all_comparisons(:,1),"accuracy"} >= blind_pass_table{all_comparisons(:,2),"accuracy"};
%disp("Finsihed getting is left better col")

%now we calculate the magnitude of the differences (Magnitude meaning abs
%difference)
mag_of_acc_differences = abs(blind_pass_table{all_comparisons(:,1),"accuracy"} -blind_pass_table{all_comparisons(:,2),"accuracy"});
disp("Finished calculating magnitude of differences")

%now we want to categorize the mag of accuracy differences
%they'll be increasing in magnitude by 10
list_of_magnitudes = 1:10:100;
cell_array_of_accuracy_magnitudes = cell(size(list_of_magnitudes,2),1);
for i=1:length(list_of_magnitudes)-1
    c1 = mag_of_acc_differences <= list_of_magnitudes(i+1)-1;
    c2 = mag_of_acc_differences > list_of_magnitudes(i)-1;

    %first we must get the indexes of the rows that fall within the     current
    %bin
    [cell_array_of_accuracy_magnitudes{i},~] = find(c1 & c2);
end

%get list of how many different combinations of the histogram feature you can have
max_num_hists = sum(contains(list_of_features_to_add,"histogram"));
table_of_all_hists = [];
parfor i=1:max_num_hists
    all_possible_combinations = nchoosek(1:max_num_hists,i);
    all_possible_combinations = num2cell(all_possible_combinations,2);
    table_of_all_hists = [table_of_all_hists;table(all_possible_combinations,'VariableNames',["permutations_of_hists"])];
end


%get list of how many different combinations of the waveforms feature you can have
max_num_waveforms = sum(contains(list_of_features_to_add,"mean_waveform"));
table_of_all_waveforms = [];
parfor i=1:max_num_waveforms
    all_possible_combinations = nchoosek(1:max_num_waveforms,i);
    all_possible_combinations = num2cell(all_possible_combinations,2);
    table_of_all_waveforms = [table_of_all_waveforms;table(all_possible_combinations,'VariableNames',["permutations_of_waveforms"])];
end

%get a list of how many different ways you can combimbe waveforms and
%histograms
array_of_all_mean_wf_and_hist_combos = combvec(1:size(table_of_all_waveforms,1),1:size(table_of_all_hists,1)).';

%set some hyperparameters for the series of trainings we will be doing
number_of_layers = 1:8;
filter_sizes = 5:5:20;
num_mean_wave_and_hist_combos = 1:size(array_of_all_mean_wf_and_hist_combos);

%get a table which tells you all possible permutations of the training sets
%you wish to create
permutations_table = get_table_of_all_permutations_for_nn_training([ ...
    "num_layers", ...
    "filter_sizes", ...
    "which_hists_and_waves"], ...
    number_of_layers,filter_sizes,num_mean_wave_and_hist_combos);

%calculate how many batches we need to run in order to finish training
%(doing it this way manages memory issues)
number_of_batches_required_to_run_all_permutations = ceil(size(permutations_table,1) / c.NumWorkers);

%now navigate into the dir to save results to
cd(dir_to_save_results_to);

%now we begin data assembly
disp("Beginning training set assembly");

%this first for loop is used to navigate through the levels of difficulty
%it starts with the easiest (located at the end of the cell_array_of_accuracy_magnitudes) and
%navigates to progressively harder difficulties (found at the beginning of
%cell_array_of_accuracy_magnitudes)

for difficulty_level=length(cell_array_of_accuracy_magnitudes):-1:1
    if isempty(cell_array_of_accuracy_magnitudes{difficulty_level})
        continue;
    end

    indexes_to_use= unique(reshape(all_comparisons(cell_array_of_accuracy_magnitudes{difficulty_level},:),1,[]),'stable');
    limited_blind_pass_table = blind_pass_table(indexes_to_use,:);
    assembled_data = assemble_data_for_neural_net(list_of_features_to_add,limited_blind_pass_table,config);

    %an unfortunate but necessary redundant calculation
    all_possible_ways_to_select_two_clusters = nchoosek(1:height(limited_blind_pass_table),2);
    is_left_better_col = limited_blind_pass_table{all_possible_ways_to_select_two_clusters(:,1),"accuracy"} >= limited_blind_pass_table{all_possible_ways_to_select_two_clusters(:,2),"accuracy"};
    for k=1:number_of_batches_required_to_run_all_permutations
        place_counter = 1;
        training_sets = cell(num_workers,1);
        filter_sizes_cell_array =  cell(num_workers,1);
        num_layers_cell_array =  cell(num_workers,1);

        %first get the row which determines which waveform and histogram
        %combination will be used
        which_waveform_and_histogram= permutations_table{k,"which_hists_and_waves"};

        %first select which waveform(s) will be used for this training set
        which_waveforms_row = array_of_all_mean_wf_and_hist_combos(which_waveform_and_histogram,1);
        which_waveform_combination = table_of_all_waveforms{which_waveforms_row,"permutations_of_waveforms"}{1};
        idxs_with_wf = contains(list_of_features_to_add,"mean_waveform");
        only_waveforms_from_assembled_data = assembled_data(idxs_with_wf);
        waveform_data = horzcat(only_waveforms_from_assembled_data{which_waveform_combination});

        %now select which histogram(s) will be used for this training set
        which_histograms_row = array_of_all_mean_wf_and_hist_combos(which_waveform_and_histogram,2);
        which_histogram_combination = table_of_all_hists{which_histograms_row,"permutations_of_hists"}{1};
        only_hists_from_assembled_data = assembled_data(contains(list_of_features_to_add,"histogram"));
        hist_data = horzcat(only_hists_from_assembled_data{which_histogram_combination});

        num_layers_cell_array{place_counter} = permutations_table{i,"num_layers"};
        filter_sizes_cell_array{place_counter} = permutations_table{i,"filter_sizes"};

        %now normalize the grade data
        grades_data = normalize_data(assembled_data(contains(list_of_features_to_add,"grades")),-1,1);
        grades_data = grades_data{1};

        size_data =assembled_data{contains(list_of_features_to_add,"size")};

        %now put the data into a single array
        training_set_array = [waveform_data,hist_data,grades_data,size_data];

        %now randomly select combinations of 2 for choose better
        rand_indexes = randperm(size(all_possible_ways_to_select_two_clusters,1),num_samples_per_dataset);
        random_training_data_idxs = all_possible_ways_to_select_two_clusters(rand_indexes,:);
        random_is_left_better = is_left_better_col(rand_indexes,:);

        %now assemble all the data
        training_set_data = array2table([training_set_array(random_training_data_idxs(:,1),:),training_set_array(random_training_data_idxs(:,2),:),random_is_left_better]);

        %now equalize the classes of is left better
        training_set_data = equalize_classes(array2table(training_set_data));

        %now remove any rows that may have produced nans
        training_set_data(isnan(training_set_data{:,end}),:) = [];



        % parfor i=1:size(training_sets,1)
        %     [accuracy,net,layers] = predict_acc_cat_using_leaky_relu(training_sets{i},filter_sizes_cell_array{i},num_layers_cell_array{i});
        %     net_struct = struct();
        %     net_struct.net = net;
        %     net_struct.layers = layers;
        %     save_name = sprintf('%.4f_accurate_num_layers_%i_num_neur_pr_lyer_%i dataset %i',accuracy,num_layers_cell_array{i},filter_sizes_cell_array{i},i);
        %     par_save(save_name+".mat",net_struct);
        % end
        % clear("training_sets")
    end
end

end