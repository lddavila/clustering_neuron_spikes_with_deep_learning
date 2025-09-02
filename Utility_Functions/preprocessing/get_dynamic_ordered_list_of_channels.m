function [ordered_list_of_channels] = get_dynamic_ordered_list_of_channels(config)
%get list of all available channels
list_of_files_in_channel_dir = struct2table(dir(config.DIR_WITH_OG_CHANNEL_RECORDINGS));
list_of_files_in_channel_dir(list_of_files_in_channel_dir{:,"name"}=="." | list_of_files_in_channel_dir{:,"name"}==".." ,:) = [];
file_names_as_strings_split = strrep(split(string(list_of_files_in_channel_dir{:,"name"}),"."),"c","");

channel_names = sort(str2double(file_names_as_strings_split(:,1)),'ascend');

ordered_list_of_channels = strcat("c",string(channel_names),".mat");


end