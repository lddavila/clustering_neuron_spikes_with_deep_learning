function [] = get_dictionaries_of_all_spikes_ver_3(art_tetr_array,spike_windows,dir_with_chan_recordings,timestamps,number_of_dps_per_slice,scale_factor,dictionaries_dir,config)
%tetrode_dictionary
%keys: "t" + tetrode number
%values: all channels which are part of the current dictionary
%spike_tetrode_dictionary
%keys: "t" + tetrode number
%values: the spikes for the current tetrode organized as follows
%[numwires, numspikes, numdp] = size(raw);
%numwires: number of channels
%numspikes: number of spikes
%numdp: number of datapoints
%timing_tetrode_dictionary
%channel_to_tetrode_dictionary
%keys: "c" + channel number
%values: tetrode which the current channel belongs to
%spiking_channel_tetrode_dictionary
%keys: "t"+ tetrode number
%values: a list of which channel was the actual spiking channel, ordered in the same way as spike_tetrode_dictionary
%spike_tetrode_dictionary_samples_format
%keys: "t"+tetrode number
%values: the spikes for the current tetrode organzied as follows
%[numdp, numspikes, numswires] = size(raw);
%numwires: number of channels
%numspikes: number of spikes
%numdp: number of datapoints
%timing_tetrode_dictionary

status_file = fopen(config.FP_TO_STATUS_FILE,"a");

parfor i=1:size(art_tetr_array,1)
    tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
    spike_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
    spike_tetrode_dictionary_samples_format = containers.Map('KeyType','char','ValueType','any');
    timing_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
    channel_to_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
    spiking_channel_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
    channels_in_current_tetrode = art_tetr_array(i,:);
    tetrode_dictionary("t"+string(i)) = channels_in_current_tetrode;
    sorted_spike_windows_for_current_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
    for j=1:length(channels_in_current_tetrode)
        channel_to_tetrode_dictionary("c"+string(channels_in_current_tetrode(j))) = i;
    end
    [current_slice,current_timing,current_spiking_channels,spike_slices_in_samples_format,sorted_spike_windows_for_current_tetrode] = get_slices_per_artificial_tetrode_ver_2(channels_in_current_tetrode,spike_windows,dir_with_chan_recordings,timestamps,number_of_dps_per_slice,scale_factor);



    spike_tetrode_dictionary("t"+string(i)) = current_slice;
    timing_tetrode_dictionary("t"+string(i)) = current_timing;
    spiking_channel_tetrode_dictionary("t"+string(i)) = current_spiking_channels;
    spike_tetrode_dictionary_samples_format("t"+string(i)) = spike_slices_in_samples_format;
    sorted_spike_windows_for_current_tetrode_dictionary("t"+string(i)) = sorted_spike_windows_for_current_tetrode;
    

    tetrode_dictionary = struct("tetrode_dictionary",tetrode_dictionary);
    spike_tetrode_dictionary = struct("spike_tetrode_dictionary",spike_tetrode_dictionary);
    timing_tetrode_dictionary = struct("timing_tetrode_dictionary",timing_tetrode_dictionary);
    channel_to_tetrode_dictionary = struct("channel_to_tetrode_dictionary",channel_to_tetrode_dictionary);
    spiking_channel_tetrode_dictionary = struct("spiking_channel_tetrode_dictionary",spiking_channel_tetrode_dictionary);
    spike_tetrode_dictionary_samples_format = struct("spike_tetrode_dictionary_samples_format",spike_tetrode_dictionary_samples_format);
    sorted_spike_windows_for_current_tetrode_dictionary = struct("sorted_spike_windows_for_current_tetrode_dictionary",sorted_spike_windows_for_current_tetrode_dictionary);
    

    save(fullfile(dictionaries_dir,"t"+string(i)+" tetrode_dictionary.mat"),"-fromstruct",tetrode_dictionary);
    save(fullfile(dictionaries_dir,"t"+string(i)+" spike_tetrode_dictonary.mat"),"-fromstruct",spike_tetrode_dictionary)
    save(fullfile(dictionaries_dir,"t"+string(i)+" timing_tetrode_dictionary.mat"),"-fromstruct",timing_tetrode_dictionary)
    save(fullfile(dictionaries_dir,"t"+string(i)+" channel_to_tetrode_dictionary.mat"),"-fromstruct",channel_to_tetrode_dictionary)
    save(fullfile(dictionaries_dir,"t"+string(i)+" spiking_channel_tetrode_dictionary.mat"),"-fromstruct",spiking_channel_tetrode_dictionary)
    save(fullfile(dictionaries_dir,"t"+string(i)+" spike_tetrode_dictionary_samples_format.mat"),"-fromstruct",spike_tetrode_dictionary_samples_format);
    save(fullfile(dictionaries_dir,"t"+string(i)+" sorted_spike_windows.mat"),"-fromstruct",sorted_spike_windows_for_current_tetrode_dictionary);

    
    status_message ="\n"+print_status_iter_message("get_dicationaries_of_all_spikes_ver_3.m");
    fwrite(status_file,status_message);

    % Show to UI
    % displayStatus(Config, status_message);
end
fclose(status_file);
end