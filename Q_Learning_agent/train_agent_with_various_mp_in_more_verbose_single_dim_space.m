function [] = train_agent_with_various_mp_in_more_verbose_single_dim_space()
%avg_dist_from_correct_accuracy: An absolute distance measurement from the terminal row to the actual stopping row
%a scalar between 1-100
%smaller is better as it indicates you are near the correct row
%bigger indicates you are far from the correct row
%this is calculated off 1000 tests that the agent was NOT trained on
%how to read meta data_string
%1st number: number of accuracy categories that have been tested
%2nd number: illegal move penalty
%3rd number: correct stop reward
%4th number: incorrect stop penalty
%5th number: move toward goal reward
%6th number: move away from goal penalty
%7th number: number of neurons per layer
%8th number: number of layers
%9th number: time in seconds it took to train and validate the agent
%example agent_file_name
% avg_dist_from_correct_acc_1_1st number_2nd number_3rd number_4th number_ ... _9th number_10th_number.mat

home_dir = cd("..");
addpath(genpath(pwd));
cd(home_dir);


config = spikesort_config();

parent_save_dir = config.parent_save_dir;
blind_pass_table = importdata(config.FP_TO_TABLE_OF_ALL_BP_CLUSTERS);

% c = parcluster('local');
% if ~any(contains(string(parallel.listProfiles),'local_scratch'))
% 
%     c.JobStorageLocation = config.parent_save_dir;
%     saveAsProfile(c, 'local_scratch');
% end
% 
% parpool('local_scratch', c.NumWorkers);
disp("Finished setting job directory")

blind_pass_table.OG_IDX = (1:size(blind_pass_table,1)).';
disp("Finished importing blind_pass_table")



dir_to_save_results_to = fullfile(parent_save_dir,config.DIR_TO_SAVE_RESULTS_TO);
if ~exist(dir_to_save_results_to,"dir")
    dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(dir_to_save_results_to);
end
disp("Finished Creating Save Dir")

[grade_names,all_grades]= flatten_grades_cell_array(blind_pass_table{:,"grades"},config);
[indexes_of_grades_were_looking_for,~] = find(ismember(grade_names,config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST)));
grades_array = all_grades(:,indexes_of_grades_were_looking_for);
disp("Finished Flattening Grades")


%get a table of known accuracy amounts from simulated data
presorted_table = [];
rng(0); %set the seed for reproducability
for i=2:1:100
    lower_bound = i-1;
    upper_bound = i;
    [rows_in_boundary,~] = find(blind_pass_table{:,"accuracy"}<= upper_bound & blind_pass_table{:,"accuracy"} > lower_bound);
    presorted_table = [presorted_table;blind_pass_table(rows_in_boundary(randperm(size(rows_in_boundary,1),5)),:)];
end
disp("Finished getting presorted table");

%get only the grades of the enviornment
grade_locs_for_presorted = nan(size(presorted_table,1),1);
for i=1:size(presorted_table,1)
    c1 = blind_pass_table{:,"Z Score"}==presorted_table{i,"Z Score"};
    c2 = blind_pass_table{:,"Tetrode"}==presorted_table{i,"Tetrode"};
    c3 = blind_pass_table{:,"Cluster"}==presorted_table{i,"Cluster"};
    [grade_locs_for_presorted(i),~] =find(c1 & c2 & c3);
end





rng(0);
training_idxs = randperm(round(size(blind_pass_table,1)/2));
testing_idxs = setdiff(1:size(blind_pass_table,1),training_idxs).';

possible_number_of_acc_cats = [10, 3,9,4];
for num_acc_cats=possible_number_of_acc_cats
    [~,number_of_features,cell_array_of_grades,acc_cat_dividers] = get_environment_and_nn_dims(num_acc_cats,presorted_table,size(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST,2),grades_array);

    ResetHandle = @() custom_reset_function_for_grid_verbose_states(grades_array,blind_pass_table,training_idxs,cell_array_of_grades,acc_cat_dividers);
    % [initial_obs_info, info] = custom_reset_function(beginning_of_environment_index,size_of_blind_pass_table);

    number_of_layers = 10:1:1005;
    filter_sizes = 50:1:100;
    possible_eps = [0.1 0.01 ];

    possible_illegal_move_penalties = [-2,-3];
    possible_rewards_for_correct_stop = [100,90,80];
    possible_penalty_for_incorrect_stop = [-100];
    possible_rewards_for_moving_towards_terminal_row = [0 1 2 3 4 5];
    possible_penalties_for_moving_away_from_terminal_rows = [0 -1 -2 -3 -4 -5];
    %how to read meta data_string
    %1st number: illegal move penalty
    %2nd number: correct stop reward
    %3rd number: incorrect stop penalty
    %4th number: move toward goal reward
    %5th number: move away from goal penalty
    %6th number: number of neurons per layer
    %7th number: number of layers
    %8th number: time in seconds it took to train
    opt = rlTrainingOptions(MaxEpisodes=size(training_idxs,2), ...
        MaxStepsPerEpisode=500, ...,
        Verbose=1,...
        SaveAgentCriteria="AverageReward", ...
        StopTrainingCriteria="None",...
        StopOnError="off");
    for illegal_move_penalty =possible_illegal_move_penalties
        for reward_for_correct_stop = possible_rewards_for_correct_stop
            for penalty_for_incorrect_stop = possible_penalty_for_incorrect_stop
                for reward_for_moving_towards_terminal_row = possible_rewards_for_moving_towards_terminal_row
                    for penalty_for_moving_away_from_terminal_row = possible_penalties_for_moving_away_from_terminal_rows

                        StepHandle = @(Action,Info) custom_step_function_for_grid_dynamic_verbose_states(Action,Info, ...
                            illegal_move_penalty, ...
                            reward_for_correct_stop, ...
                            reward_for_moving_towards_terminal_row, ...
                            penalty_for_moving_away_from_terminal_row, ...
                            penalty_for_incorrect_stop);
                        for k=1:size(possible_eps,2)
                            current_eps = possible_eps(k);
                            for i=1:size(number_of_layers,2)
                                num_layers = number_of_layers(i);
                                for j=1:size(filter_sizes,2)
                                    beginning_time = tic;
                                    num_neurons = filter_sizes(j);
                                    [agent,~,obs_info,action_info] = get_agent_and_critique_net_for_verbose_states(number_of_features,num_neurons,num_layers,current_eps);

                                    env = rlFunctionEnv(obs_info,action_info,StepHandle,ResetHandle);

                                    train(agent,env,opt);

                                    % agent.AgentOptions.CriticOptimizerOptions.LearnRate = 0.1;
                                    % agent.AgentOptions.EpsilonGreedyExploration.Epsilon=0.1;



                                    num_test_episodes =size(testing_idxs,1);
                                    true_class = nan(1,num_test_episodes);
                                    final_class = nan(1,num_test_episodes);
                                    for test_idx =1:num_test_episodes
                                        [observation,info]= custom_reset_function_for_grid_verbose_states(grades_array,blind_pass_table,test_idx,cell_array_of_grades,acc_cat_dividers);
                                        is_done = false;
                                        max_num_steps = 50;
                                        step_counter = 0;
                                        true_class(test_idx) = info.row_of_terminal_state;
                                        while ~is_done && step_counter <= max_num_steps
                                            [action,idx_act] = getAction(agent,observation);
                                            disp(action);
                                            % disp(idx_act);
                                            % disp(info.loc_of_current_step)

                                            [next_observation,reward,is_done,info] = custom_step_function_for_grid_dynamic_verbose_states(action{1},info, ...
                                                illegal_move_penalty, ...
                                                reward_for_correct_stop, ...
                                                reward_for_moving_towards_terminal_row,...
                                                penalty_for_moving_away_from_terminal_row, ...
                                                penalty_for_incorrect_stop);

                                            observation = next_observation;
                                            step_counter = step_counter+1;
                                            % disp(info.loc_of_current_step);
                                            % disp("####################")

                                        end
                                        final_class(test_idx) = info.loc_of_current_step;
                                    end
                                    number_of_matches = true_class==final_class;
                                    accuracy = ( sum(number_of_matches,'all')/ size(final_class,2))  * 100;

                                    elapsed_time = toc(beginning_time);
                                    file_save_name = sprintf("acc_score_%.2f_%i_%i_%i_%i_%i_%i_%i_%i_%.2f.mat", ...
                                        accuracy, ...
                                        num_acc_cats,...
                                        illegal_move_penalty, ...
                                        reward_for_correct_stop, ...
                                        penalty_for_incorrect_stop, ...
                                        reward_for_moving_towards_terminal_row, ...
                                        penalty_for_moving_away_from_terminal_row, ...
                                        num_layers,...
                                        num_neurons,...
                                        elapsed_time);

                                    agent_struct = struct("ag",agent);
                                    save(fullfile(dir_to_save_results_to,file_save_name),"-fromstruct",agent_struct)
                                    fprintf("Finished training agent, it took %f seconds\n",elapsed_time);






                                end
                            end
                        end
                    end
                end
            end
        end
    end
end




end