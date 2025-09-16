function [] = get_dictionaries_of_all_spikes_ver_3(art_tetr_array,spike_windows_dir,dir_with_chan_recordings,timestamps,number_of_dps_per_slice,scale_factor,dictionaries_dir,config)
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
print_status_bar(num_iterations,"get_dictionaries_of_all_spikes_ver_3.m")
already_done = config.ALREADY_DONE_FILES;
for i=1:size(art_tetr_array,1)
    channels_in_current_tetrode = art_tetr_array(i,:);
    all_channels_are_available = channels_in_current_tetrode==list_of_available_channels;
    if ~all(any(all_channels_are_available))
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
    dict_fpths = [fp_for_tetrode_dict,fp_for_spike_tetrode_dict,fp_for_timing_tetrode_dict,fp_for_channel_to_tetrode_dict,fp_to_spiking_channel_tetrode_dict,fp_to_spike_tetrode_dictionary_samples_format,fp_to_sorted_spike_windows];
    if all(ismember(dict_fpths,already_done))
        send(q,[]);
        continue;
    end

    tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
    channel_to_tetrode_dictionary = containers.Map('KeyType','char','ValueType','any');
   
 
    tetrode_dictionary("t"+string(i)) = channels_in_current_tetrode;
    for j=1:length(channels_in_current_tetrode)
        channel_to_tetrode_dictionary("c"+string(channels_in_current_tetrode(j))) = i;
    end
    get_slices_per_artificial_tetrode_ver_2(channels_in_current_tetrode,spike_windows_dir,dir_with_chan_recordings,timestamps,number_of_dps_per_slice,scale_factor,i,dict_fpths);
    tetrode_dictionary = struct("tetrode_dictionary",tetrode_dictionary);
    channel_to_tetrode_dictionary = struct("channel_to_tetrode_dictionary",channel_to_tetrode_dictionary);
    par_save(fp_for_tetrode_dict,tetrode_dictionary);
    par_save(fp_for_channel_to_tetrode_dict,channel_to_tetrode_dictionary)
    send(q,[]);
end

end