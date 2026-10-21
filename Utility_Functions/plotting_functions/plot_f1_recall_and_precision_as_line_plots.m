function [] = plot_f1_recall_and_precision_as_line_plots(score_matrix,x_data_certainty,legend_labels)
all_markers = ["diamon","square","o","*","x"];
for i=1:size(score_matrix,1)
    x_data = x_data_certainty;
    y_data = score_matrix(i,:);
    plot(x_data,y_data,"DisplayName",legend_labels(i),"LineWidth",3,'Marker',all_markers(i));
    hold on;
end
ylim([80,100]);
xlim([0.5,1])
end