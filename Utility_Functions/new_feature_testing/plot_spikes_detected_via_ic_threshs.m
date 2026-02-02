function [] = plot_spikes_detected_via_ic_threshs(config,ordered_list_of_channels,ironclust_thresholds,channel_fp)

for k=1:length(ordered_list_of_channels)
    current_channel_data = importdata(fullfile(channel_fp,ordered_list_of_channels(k)));
    current_channel_data = filt_car_(current_channel_data,config);
    thresholds_in_microvolts = nan(length(ironclust_thresholds),1);
    channel_number = str2double(strrep(strrep(ordered_list_of_channels(1),"c",""),".mat",""));
    for i=1:length(ironclust_thresholds)
        %get the spike's
        P = struct('spkThresh', [], 'qqFactor', ironclust_thresholds(i));
        [spike_locs,~,thresholds_in_microvolts(i) ]= spikeDetectSingle_fast_(current_channel_data,P);
        %now get the beginning of the spike windows
        beginning = spike_locs - round(config.NUM_DPTS_TO_SLICE/2);
        end_of_spike = spike_locs + round(config.NUM_DPTS_TO_SLICE/2);

        spike_windows = [beginning,end_of_spike,repelem(channel_number,length(spike_locs),1),spike_locs];
        %filter out invalid indexes
        spike_windows(spike_windows(:,1)<0 | spike_windows(:,2) > length(current_channel_data)) = [];
        f = figure;
        plot(current_channel_data(cell2mat(arrayfun(@(x,y) x:y, spike_windows(1:1000,1),spike_windows(1:1000,2),'UniformOutput',false))).');
        xlabel("Dpts")
        ylabel("Microvolts")
        title(string(i)+"th threshold | in microvolts "+string(thresholds_in_microvolts(i)))

        close(f)
    end
end
end