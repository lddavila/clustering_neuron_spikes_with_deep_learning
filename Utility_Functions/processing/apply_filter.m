function [] = apply_filter(list_of_ordered_channels,config,dir_to_store_filtered_data,dir_with_channel_recordings)
config = parallel.pool.Constant(config);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = length(list_of_ordered_channels);
print_status_bar(num_iterations,"apply_filter.m")
for i=1:length(list_of_ordered_channels)
    try
    if isfile(fullfile(dir_to_store_filtered_data,list_of_ordered_channels(i)))
        send(q,[]);
        continue;
    end
    current_channel = importdata(fullfile(dir_with_channel_recordings,list_of_ordered_channels(i)));
    filtered_channel = filt_car_(current_channel,config.Value);
    par_save(fullfile(dir_to_store_filtered_data,list_of_ordered_channels(i)),filtered_channel)
    
    catch
        disp("couldn't load data")
    end
    send(q,[]);
end
end