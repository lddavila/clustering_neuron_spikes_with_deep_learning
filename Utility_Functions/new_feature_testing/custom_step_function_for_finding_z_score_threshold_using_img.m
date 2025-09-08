function [next_observation, reward, is_done, info] = custom_step_function_for_finding_z_score_threshold_using_img(action, info, config)
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
%   reward = 10 * (new_ratio - last_ratio)
%   is_done = logical

% --- defaults / guards ---
if ~isfield(info, 'tol_z'),       info.tol_z = 1e-3;       end
if ~isfield(info, 'max_steps'),   info.max_steps = inf;     end
if ~isfield(info, 'step_count'),  info.step_count = 0;      end

% Ensure bounds are consistent and within [3,4]
lower_bound = min(max(info.current_lower_bound, 3), 4);
upper_bound = max(min(info.current_upper_bound, 4), 3);
if lower_bound > upper_bound
    % Repair inverted bounds by collapsing to z_score
    lower_bound = min(max(info.z_score, 3), 4);
    upper_bound = lower_bound;
end

% Validate action
if ~ismember(action, [-1, 1])
    % Illegal action: terminate with penalty, keep state as-is
    reward = -10;
    is_done = true;
    next_observation = [info.z_score, info.last_ratio, lower_bound, upper_bound];
    return;
end

% --- boundary checks vs hard domain [3,4] (optional but safe) ---
% We’ll mainly trust [lower_bound, upper_bound], which is already clipped to [3,4].

% --- update bounds based on action ---
current_z = info.z_score;

if action == -1
    % wanting to move toward smaller z → shrink upper bound
    upper_bound = min(upper_bound, current_z);
elseif action == 1
    % wanting larger z → raise lower bound
    lower_bound = max(lower_bound, current_z);
else
    % action == 0: no-op refine (keep bounds)
end

% Keep bounds valid
if lower_bound > upper_bound
    % If this happens due to numerical ties, collapse to current_z
    lower_bound = current_z;
    upper_bound = current_z;
end

% New proposal: midpoint
proposed_z = lower_bound + 0.5 * (upper_bound - lower_bound);

% If interval is degenerate, still evaluate once at the point
current_z_score = proposed_z;

% --- run environment with new z ---
copy_of_config = config;
copy_of_config.DEFAULT_CLUSTERING_Z_SCORES = current_z_score;

new_ratio = modified_run_entire_clustering_algorithm(copy_of_config);

% --- reward shaping ---
diff_between_new_and_old = new_ratio - info.last_ratio;
reward = 10 * diff_between_new_and_old;

% --- update info / state ---
info.z_score               = current_z_score;
info.last_ratio            = new_ratio;
info.current_lower_bound   = lower_bound;
info.current_upper_bound   = upper_bound;
info.step_count            = info.step_count + 1;

% --- termination criteria ---
width = upper_bound - lower_bound;
small_move = abs(current_z_score - current_z) < info.tol_z;

is_done = false;
if width <= info.tol_z || small_move || info.step_count >= info.max_steps
    is_done = true;
end

% --- observation (include bounds so policy can “see” the interval) ---
next_observation = [current_z_score, new_ratio, lower_bound, upper_bound];
end