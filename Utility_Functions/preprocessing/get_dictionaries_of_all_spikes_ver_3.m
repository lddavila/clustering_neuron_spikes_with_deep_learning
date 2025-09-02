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


list_of_available_channels = struct2table(dir(fullfile(config.DIR_WITH_OG_CHANNEL_RECORDINGS,"*.mat")));
list_of_available_channels = string(list_of_available_channels{:,"name"});
list_of_available_channels = strrep(list_of_available_channels,".mat","");
list_of_available_channels = strrep(list_of_available_channels,"c","");
list_of_available_channels = str2double(list_of_available_channels);
q = parallel.pool.DataQueue;
afterEach(q,@print_message_using_dataqueue)
num_iterations = size(art_tetr_array,1);
print_message_using_dataqueue(num_iterations,"get_dictionaries_of_all_spikes_ver_3.m")
for i=1:size(art_tetr_array,1)
    channels_in_current_tetrode = art_tetr_array(i,:);
    all_channels_are_available = channels_in_current_tetrode==list_of_available_channels;
    if ~all(any(all_channels_are_available))
        fprintf("Tetrode %i has channels not found in the channels directory ... skipping",i);
        send(q,[]);
        continue;
    end
    fp_for_tetrode_dict =fullfile(dictionaries_dir,"t"+string(i)+" tetrode_dictionary.mat") ;
    fp_for_spike_tetrode_dict =fullfile(dictionaries_dir,"t"+string(i)+" spike_tetrode_dictonary.mat") ;
    fp_for_timing_tetrode_dict =fullfile(dictionaries_dir,"t"+string(i)+" timing_tetrode_dictionary.mat");
    fp_for_channel_to_tetrode_dict= fullfile(dictionaries_dir,"t"+string(i)+" channel_to_tetrode_dictionary.mat");
    fp_to_spiking_channel_tetrode_dict = fullfile(dictionaries_dir,"t"+string(i)+" spiking_channel_tetrode_dictionary.mat");
    fp_to_spike_tetrode_dictionary_samples_format = fullfile(dictionaries_dir,"t"+string(i)+" spike_tetrode_dictionary_samples_format.mat");
    fp_to_sorted_spike_windows = fullfile(dictionaries_dir,"t"+string(i)+" sorted_spike_windows.mat");
    if all(ismember([fp_for_tetrode_dict,fp_for_spike_tetrode_dict,fp_for_timing_tetrode_dict,fp_for_channel_to_tetrode_dict,fp_to_spiking_channel_tetrode_dict,fp_to_spike_tetrode_dictionary_samples_format,fp_to_sorted_spike_windows],config.ALREADY_DONE_FILES ))
        disp("Already computed dictionary ... skipping")
        send(q,[]);
        continue;
    end

    tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
    spike_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
    spike_tetrode_dictionary_samples_format = containers.Map('KeyType','char','ValueType','any');
    timing_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
    channel_to_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
    spiking_channel_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
    
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
    


    par_save(fp_for_tetrode_dict,tetrode_dictionary);
    par_save(fp_for_spike_tetrode_dict,spike_tetrode_dictionary)
    par_save(fp_for_timing_tetrode_dict,timing_tetrode_dictionary)
    par_save(fp_for_channel_to_tetrode_dict,channel_to_tetrode_dictionary)
    par_save(fp_to_spiking_channel_tetrode_dict,spiking_channel_tetrode_dictionary)
    par_save(fp_to_spike_tetrode_dictionary_samples_format,spike_tetrode_dictionary_samples_format);
    par_save(fp_to_sorted_spike_windows,sorted_spike_windows_for_current_tetrode_dictionary);

    
    % status_message ="\n"+print_status_iter_message("get_dicationaries_of_all_spikes_ver_3.m");
    % fwrite(status_file,status_message);
    send(q,[]);
end
% fclose(status_file);
end