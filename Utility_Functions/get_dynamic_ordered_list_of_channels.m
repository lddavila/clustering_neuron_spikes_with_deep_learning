function [] = get_dynamic_ordered_list_of_channels(config)
ordered_list_of_channels = repelem("",1,config.max_channel_number);
for i=1:config.max_channel_number
    ordered_list_of_channels(i) = sprintf('c%d', i);
end
end