function [] = view_group_breakdown(statistics_table,selection)

unit_breakdown = statistics_table{selection(1),"Unit Breakdown"}{1};
bar_plot_values = unit_breakdown{:,"GroupCount"};
bar_plot_labels = unit_breakdown{:,"Max Overlap Unit"};
close all;
figure;
bar(bar_plot_labels,bar_plot_values);
xlabel("Unit");
ylabel("Number of Appearences")
title('Unit Breakdown for Selected Group');
end