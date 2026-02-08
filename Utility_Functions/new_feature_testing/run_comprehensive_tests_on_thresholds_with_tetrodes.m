function [] = run_comprehensive_tests_on_thresholds_with_tetrodes(varargin)
%will run comprehensive pc1 pc2 tests with varying channel numbers to see
%how we perform on various numbers of channels


home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir)

config = spikesort_config();




%overwrite the base path if testing locally
if ~isempty(varargin)
    config.data_dir = varargin{1};
    config.parent_save_dir = varargin{1};
end

%create a file to save everything to
results_file = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"PC1_vs_PC2_thresholds_with_varying_ch_nums_2"));

%get all unit location files
list_of_all_files = struct2table(dir(fullfile(config.data_dir, '**', '*')));
list_of_all_files = list_of_all_files(string(list_of_all_files{:,"name"})=="neuron_unit_locations.mat",:);

%meta deta parameters for testing
num_neurons_to_test_per_rec = 5;
number_of_channels_to_try = 2:1:6;
multipliers_to_try = 6:.1:15;
config.Multipliers = multipliers_to_try;
all_table = {};
recording_names_array = ["10_600Neuron300SecondRecordingWithLevel10Noise","1_600Neuron300SecondRecordingWithLevel1Noise","5_600Neuron300SecondRecordingWithLevel5Noise"];

for rec_count=3:height(list_of_all_files)
    %set the randoms seed for reproducability
    rng(0);
    unit_loc = importdata(fullfile(list_of_all_files{rec_count,"folder"}{1},list_of_all_files{rec_count,"name"}{1}));
    channel_loc = importdata(fullfile(list_of_all_files{rec_count,"folder"}{1},"channel_locations.mat"));


    %randomly select units
    random_unit_idxs = randperm(length(unit_loc),num_neurons_to_test_per_rec);
    random_unit_locs = unit_loc(random_unit_idxs,:);

    for rand_un_count=1:length(random_unit_idxs)
        %calculate distance between the current unit and all the channels
        current_unit_loc = random_unit_locs(rand_un_count,1:2);
        current_unit_number = random_unit_idxs(rand_un_count);
        dists = vecnorm(channel_loc - current_unit_loc, 2, 2);
        dist_table = array2table(dists);
        dist_table.("channel_number") = (1:length(dists)).';
        dist_table = sortrows(dist_table,"dists","ascend");


        %build tetrodes with varying channel #s so we can try and define
        %what number produces highest accuracy generally
        for channel_counter=1:length(number_of_channels_to_try)

            current_num_channels = number_of_channels_to_try(channel_counter);
            channel_list = dist_table{1:current_num_channels,"channel_number"}.';
            local_config = config;
            ordered_list_of_channels = strcat("c",string(channel_list),".mat");
            recording_name = recording_names_array(rec_count);
            local_config.GT_FP = fullfile(local_config.data_dir,recording_name,"ground_truth","ground_truth.mat");
            local_config.TIMESTAMP_FP = fullfile(local_config.data_dir,recording_name,"timestamps","timestamps.mat");
            local_config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(local_config.data_dir,recording_name,"recordings_by_channel");
            local_config.ART_TETR_ARRAY = channel_list;


            for use_pc2=0:1
                try
                    if use_pc2
                        add_to = "PC2";
                    else
                        add_to = "PC1";
                    end
                    local_config.BLIND_PASS_DIR_PRECOMPUTED = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(results_file,"rec_count"+string(rec_count)+"_"+strjoin(strrep(ordered_list_of_channels,".mat",""),"_"))+add_to);
                    if ~isfile(fullfile(local_config.BLIND_PASS_DIR_PRECOMPUTED,"blind_pass_table","blind_pass_table.mat"))
                        [blind_pass_table,fp_to_bp_table,local_config]= run_entire_clustering_algorithm_ver_2(local_config,'ordered_list_of_channels',ordered_list_of_channels);
                        fp_to_bp_table =fullfile(fp_to_bp_table,"blind_pass_table.mat");
                        %add pc label
                        blind_pass_table.which_pc = repelem(add_to,size(blind_pass_table,1),1);

                        %add channel numbers
                        blind_pass_table.channels = repelem({channel_list},size(blind_pass_table,1),1);
                        %save
                        par_save(fp_to_bp_table,blind_pass_table);

                    else
                        fp_to_bp_table = fullfile(local_config.BLIND_PASS_DIR_PRECOMPUTED,"blind_pass_table","blind_pass_table.mat");
                        blind_pass_table = importdata(fp_to_bp_table);
                    end
                    %get accuracy and overlap for this test bp table
                    beginning_time = tic;
                    local_config.TIME_DELTA = 0.0002; %changing time delta to match kilosort4 delta used when computing matching score
                    timestamps = importdata(local_config.TIMESTAMP_FP);
                    if ~isfile(fullfile(local_config.BLIND_PASS_DIR_PRECOMPUTED,"finished_adding_overlap_and_accuracy.txt"))
                        blind_pass_table = add_overlap_percentage_col_and_max_overlap_unit_optimized(blind_pass_table,local_config,timestamps);
                        par_save(fp_to_bp_table,blind_pass_table);
                        disp("Finished finding max overlap unit")
                        blind_pass_table= add_accuracy_col(local_config,blind_pass_table);
                        par_save(fp_to_bp_table,blind_pass_table);
                    end
                    disp("Finished Saving Accuracy");
                    end_time = toc(beginning_time);
                    fprintf("Finished adding overlap and accuracy columns it took %.2f seconds\n",end_time)
                catch
                    blind_pass_table = [];
                end
                all_table{end+1} = blind_pass_table;
            end
        end
    end
end
par_save(fullfile(results_file,"all_table.mat"),vertcat(all_table));

end