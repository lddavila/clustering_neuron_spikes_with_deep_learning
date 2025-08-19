function [] = train_complex_choose_better_with_hist()
num_samples = 100000;
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);
config = spikesort_config();
which_nn = "ch_bttr_w_hist";

blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);
parent_save_dir = config.parent_save_dir;


disp("Finished Loading Data")
dir_to_save_results_to = fullfile(parent_save_dir,"hist_choose_better");
if ~exist(dir_to_save_results_to,"dir")
    dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_results_to);
end
disp("Finished Creating directory")

%get grades from each row
[grade_names,all_grades]= flatten_grades_cell_array(blind_pass_table{:,"grades"},config);
[indexes_of_grades_were_looking_for,~] = find(ismember(grade_names,config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST)));
grades_array = all_grades(:,indexes_of_grades_were_looking_for);
disp("Finished Flattening Grades")

%get the histogram array for each row in the blind pass table
all_grades = vertcat(blind_pass_table{:,"grades"}{:});
all_hists = all_grades(:,64);


%get the mean waveform from each row
mean_waveform_array = cell2mat(blind_pass_table{:,"Mean Waveform"});
disp("Finished Getting Mean Waveform Array")






%get indexes of combinations
rng(0);
all_possible_combos = nchoosek(1:size(blind_pass_table,1),2);
random_indexes = randi(size(all_possible_combos,1),num_samples,1);
random_sample_indexes = all_possible_combos(random_indexes,:);


%get the is left better col

left_is_better_col = blind_pass_table{all_possible_combos(random_indexes,1),"accuracy"}>blind_pass_table{all_possible_combos(random_indexes,2),"accuracy"};

% assemble the neural network data
data_for_nn = [mean_waveform_array(all_possible_combos(random_indexes,1),:),...
    grades_array(all_possible_combos(random_indexes,1),:),...
    mean_waveform_array(all_possible_combos(random_indexes,2),:),...
    grades_array(all_possible_combos(random_indexes,2),:),...
    random_sample_indexes,...
    left_is_better_col];

s = RandStream('mlfg6331_64');

number_of_positives = sum(data_for_nn(:,end));

equalized_data_for_nn = data_for_nn(data_for_nn(:,end)==true,:);
idxs_of_false_samples = find(data_for_nn(:,end)==false);

random_indexes_of_false = datasample(s,idxs_of_false_samples,number_of_positives,'Replace',false);
equalized_data_for_nn = [equalized_data_for_nn;data_for_nn(random_indexes_of_false,:)];

randomized_indexes = randperm(size(equalized_data_for_nn,1));
shuffled_data_for_nn = equalized_data_for_nn(randomized_indexes,:);

disp("Finished Data Assembly")

number_of_layers = 1:1:50;
filter_sizes = [5 10 15 20 25 30 35 40 50];



remaining_idxs = shuffled_data_for_nn(:,[end-2,end-1]);
shuffled_data_for_nn(:,end-2:end-1) = [];

%get the overlap percentage
% overlap_col = get_overlap_percentage_for_nn_training_data(blind_pass_table,remaining_idxs,config);
disp("Finished getting overlap percentage array")

% get the sizes of both accuracy cols
first_size_col = cell2mat(cellfun(@size, blind_pass_table{remaining_idxs(:,1),"timestamps"}, 'UniformOutput', false));
sec_size_col = cell2mat(cellfun(@size, blind_pass_table{remaining_idxs(:,2),"timestamps"}, 'UniformOutput', false));
array_of_nn_data = [shuffled_data_for_nn(:,1:end-1),first_size_col(:,1),sec_size_col(:,1),shuffled_data_for_nn(:,end)];

home_dir = cd(dir_to_save_results_to);
% train the neural networks
disp(pwd)
possible_number_of_histograms_to_use = [1,2,3,4];

possible_permutations ={};
for i=1:size(all_hists{1},1)
    possible_permutations{end+1} =nchoosek(1:size(all_hists{1},1),i);
end
for current_perm =1:size(possible_permutations,1)
    for which_hists =1:size(possible_permutations{current_perm})
        hists_to_use = possible_permutations{current_perm}(which_hists,:);
        sample_left_hists = all_hists(remaining_idxs(:,1));
        sample_left_hists = cell2mat(cellfun(@(m) reshape(m(hists_to_use,:),1,[]),sample_left_hists, 'UniformOutput', false));
        sample_right_hists = all_hists(remaining_idxs(:,2));
        sample_right_hists = cell2mat(cellfun(@(m) reshape(m(hists_to_use,:),1,[]),sample_right_hists, 'UniformOutput', false));
        table_of_nn_data= array2table([array_of_nn_data(:,1:end-1),sample_left_hists,sample_right_hists,array_of_nn_data(:,end)]);
        parfor j=1:size(number_of_layers,2)
            num_layers = number_of_layers(j);
            for k=1:size(filter_sizes,2)
                num_neurons = filter_sizes(k);
                disp("About to begin Training");
                beginning_time = tic;
                [accuracy_score,net,~]= predict_acc_cat_using_leaky_relu(table_of_nn_data,num_neurons,num_layers);
                end_time = toc(beginning_time);

                disp("The last iteration took "+string(end_time)+" seconds")
                name_to_save_under = "accuracy score "+string(accuracy_score)+" num layers "+string(num_layers)+ " num neurons per layer"+string(num_neurons)+ " "+which_nn;
                fileID = fopen(name_to_save_under+ ".txt",'w');
                fclose(fileID);
                net_struct = struct();
                net_struct.Layers = net.Layers;
                net_struct.Connections = net.Connections;
                net_struct.net = net;
                par_save(name_to_save_under+".mat",net_struct)

            end
        end
    end
end

cd(home_dir);

end