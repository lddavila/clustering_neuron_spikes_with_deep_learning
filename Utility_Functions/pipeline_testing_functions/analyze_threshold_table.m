function [] = analyze_threshold_table(table_of_ratios,top_n_channels)
unique_channels = unique(table_of_ratios.Var1);

%get the median ratio for each channel
all_medians = zeros(length(unique_channels),1);
for i=1:length(unique_channels)
    current_channel = unique_channels(i);
    c1 = table_of_ratios{:,"Var1"}==current_channel;
    all_medians(i) = median(table_of_ratios{c1,"ratios_for_current_channel"});
end

table_of_channels_and_medians = sortrows(table(unique_channels,all_medians),"all_medians","descend");

%plot the multipliers vs ratios for the top_n_channels
f = figure;
legend_string = repelem("",1,top_n_channels);
for i=1:top_n_channels
    current_channel = table_of_channels_and_medians{i,"unique_channels"};
    legend_string(i)=current_channel;
    current_data = table_of_ratios(table_of_ratios{:,"Var1"}==current_channel,:);
    x_data = current_data{:,"Var2"};
    y_data = current_data{:,"ratios_for_current_channel"};
    plot(x_data,y_data);
    hold on;
end
xlabel("Multiplier (arbitrary units)")
ylabel("Unit Detectable on Channel")
legend(legend_string);
end