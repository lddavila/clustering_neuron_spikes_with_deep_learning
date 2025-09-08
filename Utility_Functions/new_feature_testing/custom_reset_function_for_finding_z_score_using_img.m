function [initial_observation, info] = custom_reset_function_for_finding_z_score_using_img(config)
% Domain & starting point
lower = 3;
upper = 4;
z0    = (lower + upper)/2;   % or: lower + (upper-lower)*rand

% Evaluate ratio at starting z
cfg = config;
cfg.DEFAULT_CLUSTERING_Z_SCORES = z0;
ratio0 = modified_run_entire_clustering_algorithm(cfg);

%pick a random tetrode
table_tetrodes_that_completed_min_pass = struct2table(dir(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"initial_pass_results min z_score 3.5/*output.mat")));
tetrodes_list = split(table_tetrodes_that_completed_min_pass{:,"name"}," ",2);
tetrodes_list = string(tetrodes_list{:,1});
random_tetrode = tetrodes_list(randi(length(tetrodes_list)));

%get the spikes of the random tetrode
spikes_of_random_tetr = importdata(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"dictionaries min_z_score 3.5 num_dps 60",random_tetrode + " spike_tetrode_dictonary.mat"));
spikes_of_random_tetr = spikes_of_random_tetr.spike_tetrode_dictionary;
spikes_of_random_tetr = spikes_of_random_tetr(random_tetrode);

%get the channels of the random tetrode
channels_of_rand_tetrode = importdata(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"dictionaries min_z_score 3.5 num_dps 60",random_tetrode + " tetrode_dictionary.mat"));
channels_of_rand_tetrode = channels_of_rand_tetrode.tetrode_dictionary;
channels_of_rand_tetrode = channels_of_rand_tetrode(random_tetrode);

%get the grayscale image of the spikes
gryscale_image = produce_nth_dimensional_view(spikes_of_random_tetr,channels_of_rand_tetrode);

%now reshape the grayscale image into single row of features that will
%go into the neural network
gryscale_image = double(reshape(gryscale_image,1,[]));   % 1×60,000
%info.image_features = img;  % cache for later steps


% Fill info
info.z_score              = z0;
info.last_ratio           = ratio0;
info.current_lower_bound  = lower;
info.current_upper_bound  = upper;
info.tol_z                = 1e-3;   % optional, aligns with step()
info.max_steps            = 50;     % optional
info.step_count           = 0;      % optional

% Observation matches step(): [z, ratio, lower, upper]
% normalize the initial oberservation for (hopefully) faster convergence
initial_observation = rescale([z0, ratio0, lower, upper,gryscale_image],-1,1); % 1 x 60,004
end
