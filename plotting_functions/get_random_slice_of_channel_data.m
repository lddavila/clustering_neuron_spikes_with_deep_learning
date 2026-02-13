function [] = get_random_slice_of_channel_data(dir_with_raw_recordings,how_many_channels_to_plot,separate_plots)
%set random seed for reproducable results

%get a list of all files
list_of_all_files = struct2table(dir(dir_with_raw_recordings));

end