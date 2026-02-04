function [] = run_comprehensive_tests_on_thresholds(varargin)
%now that we have run comprehensive tests on the thresholds and found that
%the only way to guarantee 80-90% coverage of the closest unit is to use a
%relatively low threshold this function will serve to show what the
%performance of using those thresholds

%the first set of results will display the performance of the clustering accuracy
%using these default thresholds and just PC1

%the second set of results display the performance of clustering accuracy
%using the default thresholds, PC1, and PC2

%the direct comparison will help us to determine which method is better

home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir)

config = spikesort_config();

data_to_test_on = importdata(config.struct_of_neuron_distance);

%randomly sample a few rows of data
rng(0) % set seed for reproducability of results
random_test_data_rows = randperm(size(data_to_test_on,1),20);
random_test_data = data_to_test_on(random_test_data_rows,:);



%overwrite the base path if testing locally
if ~isempty(varargin)
    config.base_file_path = varargin{1};
end

%create a file to save everything to
results_file = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.base_file_path,"PC1_vs_PC2_thresholds_with_thresholds"));
%store config in parallel variable to enable the
if ~isfile(fullfile(results_file,"all_table.mat"))
    parallel_config = parallel.pool.Constant(config);
    all_pc1_tables = cell(length(size(random_test_data,1)),1);
    for i=1:size(random_test_data,1)
        current_data = random_test_data(i,:);
        local_config = parallel_config.Value;
        % get the recording name for the data
        recording_name = current_data{1,6};

        %get the channel number
        %mutate the config to fir the current sample
        local_config.GT_FP = fullfile(local_config.base_file_path,recording_name,"ground_truth","ground_truth.mat");
        local_config.TIMESTAMP_FP = fullfile(local_config.base_file_path,recording_name,"timestamps","timestamps.mat");
        local_config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(local_config.base_file_path,recording_name,"recordings_by_channel");
        ordered_list_of_channels = current_data{1,8};
        channel_number = str2double(strrep(strrep(ordered_list_of_channels,"c",""),".mat",""));
        local_config.ART_TETR_ARRAY = channel_number;
        local_config.BLIND_PASS_DIR_PRECOMPUTED = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(results_file,recording_name+"_c"+string(channel_number)));

        try
            if ~isfile(fullfile(local_config.BLIND_PASS_DIR_PRECOMPUTED,"blind_pass_table","blind_pass_table.mat"))
                [blind_pass_table,fp_to_bp_table,local_config]= run_entire_clustering_algorithm_ver_2(local_config,'ordered_list_of_channels',ordered_list_of_channels);
                fp_to_bp_table =fullfile(fp_to_bp_table,"blind_pass_table.mat");
            else
                fp_to_bp_table = fullfile(local_config.BLIND_PASS_DIR_PRECOMPUTED,"blind_pass_table","blind_pass_table.mat");
                blind_pass_table = importdata(fp_to_bp_table);
            end
            %get accuracy and overlap for this test bp table

            %add a group label to the test_bp_table
            blind_pass_table.which_pc = repelem("PC1",size(blind_pass_table,1),1);

            %add a channel number
            blind_pass_table.channels = repelem({channel_number},size(blind_pass_table,1),1);


            beginning_time = tic;
            local_config.TIME_DELTA = 0.0002; %changing time delta to match kilosort4 delta used when computing matching score
            timestamps = importdata(local_config.TIMESTAMP_FP);
            if ~isfile(fullfile(local_config.BLIND_PASS_DIR_PRECOMPUTED,"finished_adding_overlap_and_accuracy.txt"))
                blind_pass_table = add_overlap_percentage_col_and_max_overlap_unit_optimized(blind_pass_table,local_config,timestamps);
                par_save(fp_to_bp_table,blind_pass_table);
                disp("Finished finding max overlap unit")
                blind_pass_table= add_accuracy_col(local_config,blind_pass_table);
                par_save(fp_to_bp_table,blind_pass_table);
            else
                disp("Overlap are already in your table.")
                disp("To recompute delete finished_adding_overlap_and_accuracy.txt");
            end
            disp("Finished Saving Accuracy");
            end_time = toc(beginning_time);
            fprintf("Finished adding overlap and accuracy columns it took %.2f seconds\n",end_time)
            all_pc1_tables{i} = blind_pass_table;
        catch
        end
    end
    %now do the exact same thing, but configure the code to use PC2
    parallel_config.Value.spikesort.use_pc2 = true;
    all_pc2_tables = cell(length(size(random_test_data,1)),1);
    for i=1:size(random_test_data,1)
        current_data = random_test_data(i,:);
        local_config = parallel_config.Value;
        % get the recording name for the data
        recording_name = current_data{1,6};

        %get the channel number
        %mutate the config to fir the current sample
        local_config.GT_FP = fullfile(local_config.base_file_path,recording_name,"ground_truth","ground_truth.mat");
        local_config.TIMESTAMP_FP = fullfile(local_config.base_file_path,recording_name,"timestamps","timestamps.mat");
        local_config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(local_config.base_file_path,recording_name,"recordings_by_channel");
        ordered_list_of_channels = current_data{1,8};
        channel_number = str2double(strrep(strrep(ordered_list_of_channels,"c",""),".mat",""));
        local_config.ART_TETR_ARRAY = channel_number;
        local_config.BLIND_PASS_DIR_PRECOMPUTED = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(results_file,recording_name+"_c"+string(channel_number))+"_pc2");

        try
            if ~isfile(fullfile(local_config.BLIND_PASS_DIR_PRECOMPUTED,"blind_pass_table","blind_pass_table.mat"))
                [blind_pass_table,fp_to_bp_table,local_config]= run_entire_clustering_algorithm_ver_2(local_config,'ordered_list_of_channels',ordered_list_of_channels);
                fp_to_bp_table =fullfile(fp_to_bp_table,"blind_pass_table.mat");
            else
                fp_to_bp_table = fullfile(local_config.BLIND_PASS_DIR_PRECOMPUTED,"blind_pass_table","blind_pass_table.mat");
                blind_pass_table = importdata(fp_to_bp_table);
            end
            %get accuracy and overlap for this test bp table

            %add a group label to the test_bp_table
            blind_pass_table.which_pc = repelem("PC2",size(blind_pass_table,1),1);

            %add a channel number
            blind_pass_table.channels = repelem({channel_number},size(blind_pass_table,1),1);


            beginning_time = tic;
            local_config.TIME_DELTA = 0.0002; %changing time delta to match kilosort4 delta used when computing matching score
            timestamps = importdata(local_config.TIMESTAMP_FP);
            if ~isfile(fullfile(local_config.BLIND_PASS_DIR_PRECOMPUTED,"finished_adding_overlap_and_accuracy.txt"))
                blind_pass_table = add_overlap_percentage_col_and_max_overlap_unit_optimized(blind_pass_table,local_config,timestamps);
                par_save(fp_to_bp_table,blind_pass_table);
                disp("Finished finding max overlap unit")
                blind_pass_table= add_accuracy_col(local_config,blind_pass_table);
                par_save(fp_to_bp_table,blind_pass_table);
            else
                disp("Overlap are already in your table.")
                disp("To recompute delete finished_adding_overlap_and_accuracy.txt");
            end
            disp("Finished Saving Accuracy");
            end_time = toc(beginning_time);
            fprintf("Finished adding overlap and accuracy columns it took %.2f seconds\n",end_time)
            all_pc2_tables{i} = blind_pass_table;
        catch
        end
    end
    %concatenate the tables so we can look at them
    all_table = [vertcat(all_pc2_tables);vertcat(all_pc1_tables)];

    %save the table
    par_save(fullfile(results_file,"all_table.mat"),all_table);
else
    all_table = importdata(fullfile(results_file,"all_table.mat"));
end

%now perform the analysis
pc1_rows = all_table(all_table{:,"which_pc"}=="PC1",:);
pc2_rows = all_table(all_table{:,"which_pc"}=="PC2",:);
figure
histogram(pc1_rows{:,"accuracy"});
figure
histogram(pc2_rows{:,"accuracy"});
end