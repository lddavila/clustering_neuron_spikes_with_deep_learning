function [next_observation, reward, is_done, info] = custom_step_function_for_finding_z_score_threshold_using_img(action, info, config,standard_lower_bound,standard_upper_bound,spike_windows_dir,timestamps,channel_wise_means,channel_wise_std)
% STEP for binary-search-like tuning of z-score.
% action: -1 -> move upper bound down (want smaller z), +1 -> move lower bound up (want larger z)
% Optional:  0 -> no-op refine (re-evaluate midpoint)
%
% info fields expected:
%   info.z_score
%   info.last_ratio
%   info.current_lower_bound
%   info.current_upper_bound
%   info.tol_z           (optional, default 1e-3)
%   info.max_steps       (optional, default inf)
%   info.step_count      (optional, default 0)
%
% Returns:
%   next_observation = [z, ratio, lower, upper]
reward = 0;
disp("Action is")
disp(action)
% --- defaults / guards ---
if ~isfield(info, 'tol_z'),       info.tol_z = 1e-3;       end
if ~isfield(info, 'max_steps'),   info.max_steps = inf;     end
if ~isfield(info, 'step_count'),  info.step_count = 0;      end

channels = info.channels_of_tetrode;
% Ensure bounds are consistent and within
% [standard_lower_bound,standard_upper_bound]
lower_bound = min(max(info.current_lower_bound, standard_lower_bound), standard_upper_bound);
upper_bound = max(min(info.current_upper_bound, standard_upper_bound), standard_lower_bound);
if lower_bound > upper_bound
    % Repair inverted bounds by collapsing to z_score
    lower_bound = min(max(info.z_score, standard_lower_bound), standard_upper_bound);
    upper_bound = lower_bound;
end

% Validate action
if ~ismember(action, [-1, 1,0])
    % Illegal action: terminate with penalty, keep state as-is
    reward = -10;
    disp("Made It to illegal action")
    is_done = true;
    next_observation = rescale([info.z_score, lower_bound, upper_bound,info.img_vector],-1,1);
    return;
end

% --- boundary checks vs hard domain standard_lower_bound and standard_upper_bound (optional but safe) ---
% Wesll mainly trust [lower_bound, upper_bound], which is already clipped to standard_lower_bound and standard_upper_bound.

% --- update bounds based on action ---
current_z = info.z_score;

%adjust the bounds if the decision calls for it
if action == -1
    % wanting to move toward smaller z → shrink upper bound
    upper_bound = min(upper_bound, current_z);
elseif action == 1
    % wanting larger z → raise lower bound
    lower_bound = max(lower_bound, current_z);
end

% Keep bounds valid
if lower_bound > upper_bound
    % If this happens due to numerical ties, collapse to current_z
    lower_bound = current_z;
    upper_bound = current_z;
end

% New proposal: midpoint
%if the the decision was to move down/up then we'll get a new z score and
%thus a new image
%if the action is 0 ie. run clustering then we do not get a new image
proposed_z = lower_bound + 0.5 * (upper_bound - lower_bound);

if action ==-1 || action ==1
    %to avoid continuous checks we impose a small cost on checks
    reward = -1;
    %get the cut spikes of the image
    spikes_of_tetr =get_spike_slices(channels,spike_windows_dir,config.DIR_WITH_OG_CHANNEL_RECORDINGS,config.NUM_DPTS_TO_SLICE,config.SCALE_FACTOR,proposed_z);

    %get the grayscale image of the spikes
    gryscale_image = produce_nth_dimensional_view(spikes_of_tetr,channels);

    %now reshape the grayscale image into single row of features that will
    %go into the neural network
    gryscale_image = double(reshape(gryscale_image,1,[]));   % 1×60,000
else
    %because clustering is expensive and we want to encourage the least
    %number of clustering possible we impose a steep cost;
    disp("made it 0")
    reward = -100;
    config.DEFAULT_CLUSTERING_Z_SCORES = proposed_z;
    disp("proposed z")
    disp(proposed_z)
    [meets_acc_ratio,blind_pass_table ]= modified_run_entire_clustering_algorithm_for_img_analysis(config,timestamps,spike_windows_dir,channels,channel_wise_means,channel_wise_std);
    disp("Finished modified clustering algorithm")
    display(blind_pass_table(:,["Z Score","Tetrode","Cluster","accuracy"]))
    disp(channels)
    if meets_acc_ratio
        reward = reward+110;
    else
        reward = reward-20;
    end
    if isempty(blind_pass_table)
        reward = reward -20; %you want to impose an even steeper if it failed to return any clusters at all cause it means it completely failed
    end
    %we'll also had a scaling reward depending on how far above/below the
    %accuracy is from the threshold
    max_accuracy = max(blind_pass_table{:,"accuracy"});
    scaling_reward = max_accuracy - 80;
    reward = scaling_reward * 10;
    %disp("made the decision to run clustering")
    is_done = true;
    next_observation = rescale([info.z_score, lower_bound, upper_bound,info.img_vector],-1,1);
    disp("reward is")
    display(reward)
    disp("______________________________________________________________________________")
    return;
end



% --- update info / state ---
info.z_score               = proposed_z;
info.current_lower_bound   = lower_bound;
info.current_upper_bound   = upper_bound;
info.step_count            = info.step_count + 1;
info.img_vector = gryscale_image;
% --- termination criteria ---
width = upper_bound - lower_bound;
small_move = abs(proposed_z - current_z) < info.tol_z;

is_done = false;
if width <= info.tol_z || small_move || info.step_count >= info.max_steps
    disp("Made it to the tolerance check")
    is_done = true;
end

% --- observation (include bounds so policy can “see” the interval) ---
next_observation = rescale([proposed_z, lower_bound, upper_bound,gryscale_image],-1,1);
end