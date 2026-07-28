function [] = test_cluster_splitting()
%format the path
home_dir = cd("..");
cd("..");
disp(pwd);
addpath(genpath(fullfile(pwd,"Utility_Functions")));
addpath(genpath(fullfile(pwd,"clustering-master")));
addpath(genpath(fullfile(pwd,"Grading_scripts")));
addpath(genpath(fullfile(pwd,"Neural_Networks")));
cd(home_dir);

%get a config file
config = spikesort_config();
config.RECORDING_NAME = "10_600Neuron300SecondRecordingWithLevel10Noise";

% set config parameters given the system
if contains(pwd,"10595")
    config.GT_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
    config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
    config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"recordings_by_channel");
    blind_pass_table = importdata("/scratch2/10595/lddavila/clustering_neuron_spikes_with_deep_learning/Default_Results_Dir/temp_dir/blind_pass_table.mat");
elseif contains(pwd,"C:\Users\ldd77\")
    % ext_drive_fp = "F:";
    config.GT_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"ground_truth","ground_truth.mat");
    config.TIMESTAMP_FP = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"timestamps","timestamps.mat");
    config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data",config.RECORDING_NAME,"recordings_by_channel");
    blind_pass_table = importdata("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\f1_clustering_tests_10_600Neuron300SecondRecordingWithLevel10Noise\blind_pass_table.mat");
end

config.ground_truth_cell_array = importdata(config.GT_FP);
config.debug_with_ground_truth = true;
config.use_new_spike_detection = false;
config.has_ground_truth = true;

config.BLIND_PASS_DIR_PRECOMPUTED = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"testing_cluster_splitting_population"));

config.error_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"error_reports"));
bp_table_after_splitting_save_name = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"bp_table_after_splitting.mat");
disp(bp_table_after_splitting_save_name);
if ~isfile(bp_table_after_splitting_save_name)
    bp_table_after_splitting = split_clusters_with_alt_dimensions(blind_pass_table,config,'plot_the_debug',false);
    par_save(bp_table_after_splitting_save_name,bp_table_after_splitting);
    disp("Successfully obtained the split table")
else
    bp_table_after_splitting = importdata(bp_table_after_splitting_save_name);
    disp("Successfully loaded the split table")
end
existingPool = gcp('nocreate');
if ~isempty(existingPool)
    delete(existingPool);
end
%get grades for the new table

bp_table_after_splitting_vars = string(bp_table_after_splitting.Properties.VariableNames);
disp("about to begin grading")

cluster = parcluster("Processes");
num_workers = max(1, floor(cluster.NumWorkers / 8));
fprintf("Have %i workers\n",num_workers);
time_start = tic();
poolobj = parpool(cluster, 16);
time_end = toc(time_start);
fprintf("Starting the parallel pool took %.2f seconds\n",time_end)
bp_table_after_splitting =add_grades_col_to_bp_from_dir(bp_table_after_splitting,"/scratch2/10595/lddavila/clustering_neuron_spikes_with_deep_learning/Default_Results_Dir/testing_cluster_splitting_population/initial_pass min z_score 3 grades_after_splitting");
% if ~ismember("grades",bp_table_after_splitting_vars)
%     bp_table_after_splitting = get_grades_for_split_cluster(bp_table_after_splitting,config,'optional_alternate_grade_path',"_after_splitting");
%     par_save(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"bp_split_after_grading.mat"),bp_table_after_splitting);
% else
%     bp_table_after_splitting = importdata(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"bp_split_after_grading.mat"));
% end
disp("Finished grading")


%plot any clusters that produced imaginary grades
place_to_save_imaginary_plots = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"clusters_that_created_imaginary_grades"));

number_of_plots_saved = 0;
disp("About to create imaginary plots")
for i=1:height(bp_table_after_splitting)
    if number_of_plots_saved > 100
        break;
    end
    current_grades =  get_all_grades_with_padding(bp_table_after_splitting(i,:),config,'is_split',true);
    save_name ="row"+string(i)+"of_bp_table_after_splitting.mat";
    if ~isreal(current_grades)
        general_peak_plotting_function(bp_table_after_splitting(i,:),true,place_to_save_imaginary_plots,save_name,config,"blind_pass_table")
        number_of_plots_saved = number_of_plots_saved+1;
    end
    fprintf("%i/%i\n",i,height(bp_table_after_splitting));
end
disp("finished creating imaginary plots")

%add the mean waveform to the blind pass table

% if ~ismember("mean_waveform_rep_wire_1",bp_table_after_splitting_vars)
bp_table_after_splitting = get_template_spike_for_split_clusters(bp_table_after_splitting,config);
par_save(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"bp_graded_with_mean_wf.mat"),bp_table_after_splitting);
% end
disp("Finished getting mean waveform");

grouped_clusters_save_name = fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"bp_table_after_splitting_and_grouping.mat");
grouped_clusters = simple_grouping_parallel_ensemble(bp_table_after_splitting,config,false,'use_true_accuracy_instead_of_nn_filter',true);
par_save(grouped_clusters_save_name,grouped_clusters);
%extract grades from bp_table_after_splitting
% list_of_features_to_add = ["grades 3"];
% grades_array = [cell2mat(assemble_data_for_neural_net(list_of_features_to_add,bp_table_after_splitting,config))];
% table_of_nets = struct2table(dir(fullfile(config.dir_of_prob_dist_nets,"*.mat")));
% net_names = string(table_of_nets.name);
% split_net_names = split(net_names,"_");
% [~,where_below_ends ]= find(split_net_names=="below");
% net_nums = arrayfun(@(i) split_net_names(i, where_below_ends(i)+1), ...
%     (1:size(split_net_names,1))');
% 
% table_of_nets.threshold = str2double(net_nums);
% table_of_nets = sortrows(table_of_nets,"threshold","ascend");
% 
% dir_to_nn_sets = "C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\probability_distr_nets_equalized_difficulty_grades_3_with_temp_scaling";
% true_accuracy = bp_table_after_splitting{:,"accuracy"};
% f = figure;
% tiledlayout('flow');
% nexttile();
% histogram(true_accuracy,'BinEdges',1:1:100);
% ylabel("Frequency")
% xlabel("Accuracy")
% 
% 
% [~,unscaled_certainties ]= get_certainties_of_all_previous_nets(string(table_of_nets.name),dir_to_nn_sets,grades_array);
% all_positive =all(unscaled_certainties>0,2) | sum(unscaled_certainties>0,2)>80 ;
% all_negative = all(unscaled_certainties<0,2) | sum(unscaled_certainties<0,2)>80;
% to_eliminate = all_positive | all_negative;
% true_accuracy(to_eliminate) = [];
% unscaled_certainties(to_eliminate,:) = [];
% 
% nexttile();
% histogram(true_accuracy,'BinEdges',1:1:100)
% ylabel("Frequency")
% xlabel("Accuracy")
end