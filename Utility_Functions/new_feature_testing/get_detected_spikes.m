function [unit_ratio,noise_ratio,raw_unit_numbers,raw_noise_numbers,thresholds] = get_detected_spikes(current_channel_data,default_thresholds,ironclust_thresholds,unit_gr_tr,config,fp_to_save_to)
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
%unit_ratio
%between 0-1
%what ratio of the unit's spikes are found with spike detection
%noise_ratio
%between 0-1
%how many of the unit's spikes are found by spike detection divided by
%number of spikes found by spike detection
%raw_unit_number
%how many of the unit's spikes appear
%raw_noise_number
%how many non-unit spikes appear

unit_ratio = nan;
noise_ratio = nan;
raw_noise_numbers = nan;
raw_unit_numbers = nan;
thresholds = nan;
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)

if ~config.use_new_spike_detection
    %get the z score data for the current channel
    thresholds = zeros(length(default_thresholds),1);

    [channel_wise_z_score,mu,sigma ]= zscore(current_channel_data* config.SCALE_FACTOR);
    unit_ratio= zeros(length(unit_gr_tr),length(default_thresholds));
    noise_ratio = zeros(length(unit_gr_tr),length(default_thresholds));
    raw_noise_numbers = zeros(length(unit_gr_tr),length(default_thresholds));
    raw_unit_numbers = zeros(length(unit_gr_tr),length(default_thresholds));
    num_iterations = length(unit_gr_tr)*length(default_thresholds);

    print_status_bar(num_iterations,"")
    for i=1:length(default_thresholds)
        desired_z_score = default_thresholds(i);
        thresholds(i) = mu+(sigma*desired_z_score);
        mutated_channel_data = current_channel_data;
        mutated_channel_data(abs(channel_wise_z_score) < desired_z_score) = 0;

        parfor k=1:length(unit_gr_tr)
            ground_truth_spike_idxs = unit_gr_tr{k};
            %get the spikes for the current window

            [~,spikes_for_current_channel] = findpeaks(mutated_channel_data);

            %now use the ground truth how much of the desired unit is actually in the

            raw_unit_number =sum(ismembertol(double(ground_truth_spike_idxs),spikes_for_current_channel,0.0001),"all") ;
            raw_unit_numbers(k,i) = raw_unit_number;
            raw_noise_numbers(k,i) = length(spikes_for_current_channel) - raw_unit_number ;
            unit_ratio(k,i)= raw_unit_number / length(ground_truth_spike_idxs);
            noise_ratio(k,i) = (length(spikes_for_current_channel) -raw_unit_number)/ length(spikes_for_current_channel);
            send(q,[]);
        end


        if mod(desired_z_score,1)==0
            f = figure;
            plot(current_channel_data(1:min([10000,length(current_channel_data)])))
            counter = 0;
        end
        
        hold on;
        actual_y_line_value = abs(current_channel_data(find(abs(channel_wise_z_score)>=desired_z_score,1)));
        if ~isempty(actual_y_line_value)
            yline(actual_y_line_value,'Label',sprintf("%.2f",actual_y_line_value));
        end
        counter = counter+1;

        if counter==10 || i==length(default_thresholds)
            saveas(f,fullfile(fp_to_save_to,"thresholds "+string(i-10)+" to "+string(i)+".fig"));
            close(f);
        end
        


    end


else
    %if you aren't using the default spike detection then we'll use the one
    %that was taken from ironclust
    %apply bandpass filter to data
    num_iterations = length(unit_gr_tr) *length(ironclust_thresholds);
    print_status_bar(num_iterations,"")
    current_channel_data_mut = filt_car_(current_channel_data,config);

    unit_ratio= zeros(length(unit_gr_tr),length(ironclust_thresholds));
    noise_ratio = zeros(length(unit_gr_tr),length(ironclust_thresholds));
    raw_noise_numbers = zeros(length(unit_gr_tr),length(ironclust_thresholds));
    raw_unit_numbers = zeros(length(unit_gr_tr),length(ironclust_thresholds));
    thresholds = zeros(length(default_thresholds),1);
    for i=1:length(ironclust_thresholds)
        P = struct('spkThresh', [], 'qqFactor', ironclust_thresholds(i));
        [spikes_for_current_channel, ~, thresh1] = spikeDetectSingle_fast_(current_channel_data_mut,P);
        thresholds(i) = thresh1;
        for k=1:length(unit_gr_tr)
            ground_truth_spike_idxs = unit_gr_tr{k};
            raw_unit_number = nnz(ismember(ground_truth_spike_idxs, spikes_for_current_channel));   % exact matches ;
            raw_noise_numbers(k,i) = length(spikes_for_current_channel) - raw_unit_number;
            
            raw_unit_numbers(k,i) = raw_unit_number;

            unit_ratio(k,i) = raw_unit_number / length(ground_truth_spike_idxs);
            if raw_noise_numbers(k,i) < 0 || raw_unit_number < 0
                disp("something wrong/weird")
            end
            noise_ratio(k,i) = (length(spikes_for_current_channel) -raw_unit_number)/ length(spikes_for_current_channel);
            send(q,[])
        end

        if mod(ironclust_thresholds(i),1)==0
            f =figure;
            counter = 0;
            plot(current_channel_data_mut(1:min([10000,length(current_channel_data_mut)])))
        end
        
        hold on;
        yline(thresh1,'Label',sprintf("%.2f",thresh1));
        counter = counter+1;

        if counter==10 || i==length(ironclust_thresholds)
            saveas(f,fullfile(fp_to_save_to,"thresholds "+string(i-10)+" to "+string(i)+".fig"));
            close(f);
        end


    end



end




end