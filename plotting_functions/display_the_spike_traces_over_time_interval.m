function [] = display_the_spike_traces_over_time_interval(dir_with_continous_recordings,list_of_channels,time_bounds,timestamps_dir,config,tetrode_number)
%should be built generally enough to take both the raw spike traces
%and the ones with artifacts removed


% tiledlayout("vertical",'TileSpacing','tight');
all_ts = importdata(fullfile(timestamps_dir,"timestamps.mat"));


indexes_to_keep = all_ts <= time_bounds(2) & all_ts>= time_bounds(1);
% all_ts = all_ts(indexes_to_keep); %remove any ts outside the diesired timebounds
figure('units','normalized','outerposition',[0 0 1 1])
t = tiledlayout('vertical');
for i=1:length(list_of_channels)
    nexttile();
    current_channel_data = importdata(dir_with_continous_recordings+"\"+list_of_channels(i)+".mat");
    if class(current_channel_data)=="int"
        current_channel_data = double(current_channel_data);
    end
    x_data =all_ts(indexes_to_keep) ;
    y_data =current_channel_data(indexes_to_keep) *config.SCALE_FACTOR ;
    plot(x_data,y_data);
    
    title(list_of_channels(i))
    xticks([]);
    yticks([min(y_data),max(y_data)])
    

    if i==length(list_of_channels)
        xticks([x_data(1),x_data(end)]);
    end

    box off;
end
title(t,"Tetrode:"+string(tetrode_number))
xlabel(t,"Time (seconds)");
ylabel(t,"Amplitude (microvolts)");
end