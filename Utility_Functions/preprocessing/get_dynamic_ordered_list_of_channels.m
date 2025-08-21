function [ordered_list_of_channels] = get_dynamic_ordered_list_of_channels(config)
%get list of all available channels
list_of_files_in_channel_dir = struct2table(dir(config.DIR_WITH_OG_CHANNEL_RECORDINGS));
list_of_available_channels = string(list_of_files_in_channel_dir{contains(string(list_of_files_in_channel_dir{:,"name"}),".mat"),"name"});
ordered_list_of_channels = repelem("",1,config.max_channel_number);
for i=1:config.max_channel_number
    ordered_list_of_channels(i) = sprintf('c%d', i);
end
end