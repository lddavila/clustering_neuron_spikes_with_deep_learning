function [] = train_nn_to_predict_over_1_percent_overlap()
home_dir =cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);
number_of_layers = 1:1:50;
% number_of_layers = [6];
filter_sizes = [5 10 15 20 25 30 35 40 50];
% filter_sizes = [35];

config = spikesort_config;

if config.ON_HPC
    parent_save_dir = config.parent_save_dir_ON_HPC;
    blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS_ON_HPC);
    dir_for_jobs = config.parent_save_dir_ON_HPC;
    c = parcluster('local');
    c.JobStorageLocation = dir_for_jobs;
    saveAsProfile(c, 'local_scratch');
    parpool('local_scratch', 37);
    disp("Finished setting batch location");
else
    parent_save_dir = config.parent_save_dir;
    blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);
end
disp("Finished loading the updated table of overlap")

granularity_levels = 1:5;
dir_to_save_accuracy_cat_to = fullfile(parent_save_dir,config.DIR_TO_SAVE_RESULTS_TO);
which_nn = config.WHICH_NEURAL_NET;
if ~exist(dir_to_save_accuracy_cat_to,"dir")
    dir_to_save_accuracy_cat_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_accuracy_cat_to);
end

[grade_names,all_grades]= flatten_grades_cell_array(blind_pass_table{:,"grades"},config);
[indexes_of_grades_were_looking_for,~] = find(ismember(grade_names,config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST)));
grades_array = all_grades(:,indexes_of_grades_were_looking_for);
disp("Finished Flattening Grades")
mean_waveform_array = cell2mat(blind_pass_table{:,"Mean Waveform"});
for i=granularity_levels
    blind_pass_table = add_number_of_overlap_percentages_above_one_col(blind_pass_table,i);
    cd(dir_to_save_accuracy_cat_to);   

    use_mean_waveform_or_dont = [1 0];

    for use_mean_waveform=use_mean_waveform_or_dont
        for j=1:size(number_of_layers,2)
            num_layers = number_of_layers(j);
            for k=1:size(filter_sizes,2)
                num_neurons = filter_sizes(k);
                if use_mean_waveform
                    table_of_nn_data = array2table([grades_array,mean_waveform_array,blind_pass_table{:,"num_of_overlap_percentages_over_1"}]);
                    to_add = "_used_mean_waveform";
                else
                    table_of_nn_data = array2table([grades_array,blind_pass_table{:,"num_of_overlap_percentages_over_1"}]);
                    to_add = "";
                end
                %now equalize the number of appearences per class
                table_of_nn_data = equalize_classes(table_of_nn_data);
               
                beginning_time = tic;


                [accuracy_score,net,~]=predict_acc_cat_using_leaky_relu(table_of_nn_data,num_neurons,num_layers);
                end_time = toc(beginning_time);
                name_to_save_under = "acc_score_"+string(accuracy_score)+"_numbins_"+string(i)+"_num_layers_"+string(num_layers)+ "_n_n_per_layer"+string(num_neurons)+ "_"+which_nn+"_"+string(end_time)+"_seconds"+to_add;
                net_struct = struct();
                net_struct.Layers = net.Layers;
                net_struct.Connections = net.Connections;
                net_struct.net = net;

                par_save(name_to_save_under,net_struct);
            end
        end
    end
    cd(home_dir);
end

end