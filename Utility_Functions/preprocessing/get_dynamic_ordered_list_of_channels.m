function [ordered_list_of_channels] = get_dynamic_ordered_list_of_channels(config)
%get list of all available channels
list_of_files_in_channel_dir = struct2table(dir(config.DIR_WITH_OG_CHANNEL_RECORDINGS));
ordered_list_of_channels = string(list_of_files_in_channel_dir{contains(string(list_of_files_in_channel_dir{:,"name"}),".mat"),"name"});


end