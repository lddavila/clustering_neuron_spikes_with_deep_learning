function [next_observation,reward,is_done,info] = custom_step_function_for_finding_z_score_threshold(action,info,config)
%by default the is_done condition will be set to false
%get the current z score
current_z_score = info.z_score;
%first check if the action is illegal 
if action == -1 && current_z_score -0.01 < 3 % we never wanna go below 3
    reward = -10;
    is_done = true;
    return;
elseif action == 1 && current_z_score +0.01 > 4 %we never wnana go over 4
    reward = -10;
    is_done = true;
    return;
end

%now based on the action modify the config
if action == -1 %decrease the z score 
    current_z_score = current_z_score -0.01;
elseif action == 1 %increase the z score
    current_z_score = current_z_score +0.01;
end

copy_of_config = config;
copy_of_config.DEFAULT_CLUSTERING_Z_SCORES = current_z_score;
new_ratio = modified_run_entire_clustering_algorithm(copy_of_config);


%now that we have a new ratio we can compare it to the old ratio
%and scale the reward depending on the difference
diff_between_new_and_old = new_ratio - info.last_ratio;
reward = diff_between_new_and_old * 10;
is_done = false;
next_observation = [current_z_score,diff_between_new_and_old];

info.z_score = current_z_score;
info.last_ratio = new_ratio;
end