function [initial_observation, info] = custom_reset_function_for_finding_z_score_using_img(config,lower,upper,spike_windows_dir,array_of_available_tetrodes)
% Domain & starting point

z0    = (lower + upper)/2;   % or: lower + (upper-lower)*rand


%pick a random tetrode
tetrodes_list = strcat("t",string(1:size(array_of_available_tetrodes,2)));
random_tetrode_index = randi(length(tetrodes_list));
random_tetrode = tetrodes_list(random_tetrode_index);
channels_of_rand_tetrode = array_of_available_tetrodes(random_tetrode_index,:);


%get the cut spikes of the image
spikes_of_random_tetr =get_spike_slices(channels_of_rand_tetrode,spike_windows_dir,config.DIR_WITH_OG_CHANNEL_RECORDINGS,config.NUM_DPTS_TO_SLICE,config.SCALE_FACTOR,z0);

%get the grayscale image of the spikes
gryscale_image = produce_nth_dimensional_view(spikes_of_random_tetr,channels_of_rand_tetrode);

%now reshape the grayscale image into single row of features that will
%go into the neural network
gryscale_image = double(reshape(gryscale_image,1,[]));   % 1×60,000
%info.image_features = img;  % cache for later steps


% Fill info
info.z_score              = z0;
info.current_lower_bound  = lower;
info.current_upper_bound  = upper;
info.tol_z                = 1e-3;   % optional, aligns with step()
info.max_steps            = 50;     % optional
info.step_count           = 0;      % optional
info.img_vector = gryscale_image;

info.channels_of_tetrode = channels_of_rand_tetrode;

% Observation matches step(): [z, ratio, lower, upper]
% normalize the initial oberservation for (hopefully) faster convergence
initial_observation = rescale([z0, lower, upper,gryscale_image],-1,1); % 1 x 60,004
end
