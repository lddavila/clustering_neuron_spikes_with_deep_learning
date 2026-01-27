function [unit_ratio,noise_ratio] = get_detected_spikes(current_channel_data,default_thresholds,ironclust_thresholds,unit_gr_tr,config)
%INPUT:
%current_channel_data:
%   an array with the channel data in microvolts
%default_thresholds:
%   an array where every item is a z scores which will be used to filter
%ironclust_thresholds:
%   an array where every item is a threshold used by ironclust
%unit_gr_tr:
%   a cell array where each member contains idxs of that unit's spikes


%OUTPUT:
%threshold_data
%a 2 array where the dimensions have the following correlation
%dimension 1 (row) = which unit in unit_gr_tr is correlated to
%dimension 2 (col) = which overlap threshold
%every item in the 2d array is a ratio between 0-1
%the ratio can be calculated via the following formula
%   # of detected spikes that have a correlation in ground truth / # of spikes detected

unit_ratio = nan;
noise_ratio = nan;
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)

if ~config.use_new_spike_detection
    %get the z score data for the current channel
    channel_wise_z_score = zscore(current_channel_data* config.SCALE_FACTOR);
    unit_ratio= zeros(length(unit_gr_tr),length(default_thresholds));
    noise_ratio = zeros(length(unit_gr_tr),length(default_thresholds));
    num_iterations = length(unit_gr_tr)*length(default_thresholds);
    print_status_bar(num_iterations,"")
    for i=1:length(default_thresholds)
        desired_z_score = default_thresholds(i);
        parfor k=1:length(unit_gr_tr)
            ground_truth_spike_idxs = unit_gr_tr{k};
            %get the spikes for the current window
            mutated_channel_data = current_channel_data;
            mutated_channel_data(abs(channel_wise_z_score) < desired_z_score) = 0;
            [~,spikes_for_current_channel] = findpeaks(mutated_channel_data);

            %now use the ground truth how much of the desired unit is actually in the
            unit_ratio(k,i)= sum(ismembertol(double(ground_truth_spike_idxs),spikes_for_current_channel,0.0001),"all") / length(ground_truth_spike_idxs);
            noise_ratio(k,i) = sum(ismembertol(double(ground_truth_spike_idxs),spikes_for_current_channel,0.0001),"all") / length(spikes_for_current_channel);
            send(q,[]);
        end
    end
else
    %if you aren't using the default spike detection then we'll use the one
    %that was taken from ironclust
    %apply bandpass filter to data
    num_iterations = length(unit_gr_tr) *length(ironclust_thresholds);
    print_status_bar(num_iterations,"")
    current_channel_data = filt_car_(current_channel_data,config);
    unit_ratio= zeros(length(unit_gr_tr),length(ironclust_thresholds));
    noise_ratio = zeros(length(unit_gr_tr),length(ironclust_thresholds));
    for i=1:length(ironclust_thresholds)
        P = struct('spkThresh', [], 'qqFactor', ironclust_thresholds(i));
        spikes_for_current_channel = spikeDetectSingle_fast_(current_channel_data,P);
        for k=1:length(unit_gr_tr)
            ground_truth_spike_idxs = unit_gr_tr{k};
            unit_ratio(k,i) = sum(ismembertol(double(ground_truth_spike_idxs),spikes_for_current_channel,0.0001),"all") / length(ground_truth_spike_idxs);
            noise_ratio(k,i) = sum(ismembertol(double(ground_truth_spike_idxs),spikes_for_current_channel,0.0001),"all")/ length(spikes_for_current_channel);
            send(q,[])
        end

    end


end




end