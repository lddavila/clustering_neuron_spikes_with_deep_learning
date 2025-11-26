function [] = update_wf_axes(mean_waveform_plot_array,group_data)
%plot the mean waveform of all units that exist in the cluster 


unique_units_in_group = unique(group_data{:,"Max_Overlap_Unit"});
legend_string = strcat("Unit",string(unique_units_in_group));

for j=1:length(mean_waveform_plot_array)
    hold(mean_waveform_plot_array(j),'off');
    for i=1:length(unique_units_in_group)
        mean_waveform = cell2mat(group_data{group_data{:,"Max_Overlap_Unit"}==unique_units_in_group(i),"mean_waveform_rep_wire_"+string(j)});
        plot(mean_waveform_plot_array(j),mean(mean_waveform,1));
        hold(mean_waveform_plot_array(j),'on');
    end
  

end
legend(mean_waveform_plot_array(end),legend_string);
%hold(mean_waveform_plot,'off');

end