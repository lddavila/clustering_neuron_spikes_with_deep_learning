function [] = view_group_breakdown(statistics_table,selection,bar_plot_axes,mean_waveform_plot,group_data)

unit_breakdown = statistics_table{selection(1),"Unit Breakdown"}{1};
bar_plot_values = unit_breakdown{:,"GroupCount"};
bar_plot_labels = unit_breakdown{:,"Max Overlap Unit"};
bar(bar_plot_axes,bar_plot_labels,bar_plot_values./sum(bar_plot_values,"all"));

unique_units_in_group = unique(group_data{:,"Max Overlap Unit"});
legend_string = strcat("Unit",string(unique_units_in_group));
for j=1:size(mean_waveform_plot,2)
    hold(mean_waveform_plot,'off');
    current_mean_waveform_plot = mean_waveform_plot(j);
    for i=1:size(unique_units_in_group,1)
        mean_waveform = cell2mat(group_data{group_data{:,"Max Overlap Unit"}==unique_units_in_group(i),"mean_waveform_rep_wire_"+string(j)});
        plot(current_mean_waveform_plot,mean(mean_waveform,1));
        hold(current_mean_waveform_plot,'on');
    end
    if j==4
        legend(current_mean_waveform_plot,legend_string);
    end
end

%hold(mean_waveform_plot,'off');

end