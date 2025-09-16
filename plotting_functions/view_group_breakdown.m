function [] = view_group_breakdown(statistics_table,selection,bar_plot_axes,mean_waveform_plot,group_data)

unit_breakdown = statistics_table{selection(1),"Unit Breakdown"}{1};
bar_plot_values = unit_breakdown{:,"GroupCount"};
bar_plot_labels = unit_breakdown{:,"Max Overlap Unit"};
bar(bar_plot_axes,bar_plot_labels,bar_plot_values./sum(bar_plot_values,"all"));

unique_units_in_group = unique(group_data{:,"Max Overlap Unit"});
legend_string = strcat("Unit",string(unique_units_in_group));

for j=1:length(mean_waveform_plot)
    hold(mean_waveform_plot(j),'off');
    for i=1:size(unique_units_in_group,1)
        mean_waveform = cell2mat(group_data{group_data{:,"Max Overlap Unit"}==unique_units_in_group(i),"mean_waveform_rep_wire_"+string(j)});
        plot(mean_waveform_plot(j),mean(mean_waveform,1));
        hold(mean_waveform_plot(j),'on');
    end
  

end
legend(mean_waveform_plot(end),legend_string);
%hold(mean_waveform_plot,'off');

end