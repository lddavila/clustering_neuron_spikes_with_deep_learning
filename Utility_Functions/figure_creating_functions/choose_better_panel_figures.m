close all;clc;
[config,local_figure_dir] = set_up_figure_creation("name_of_calling_file","choose_better_panel_figures");
dir_of_poster_data = fullfile(config.data_dir,"data_for_poster_figs");

%get a blind pass table
blind_pass_table = load(fullfile(dir_of_poster_data,"blind_pass_table_2_ch.mat"));
blind_pass_table = blind_pass_table.data_to_save;
%% get some examples for the data
filter_out_clusters_predicted_to_be_less_than_50_perc_acc(blind_pass_table,config,"create_figures_for_choose_better_poster_panel",true,"dir_to_save_panel_figures_to",local_figure_dir);

%% get the examples where both are above 70
filter_out_clusters_predicted_to_be_less_than_50_perc_acc(blind_pass_table,config,"create_figures_for_choose_better_poster_panel",true,"dir_to_save_panel_figures_to",local_figure_dir,"only_above_60",true);

%% get data to estimate performance
[rows_to_keep,filter_mask,estimated_accuracy] = filter_out_clusters_predicted_to_be_less_than_50_perc_acc(blind_pass_table,config);
%% get the histogram for accuracy distribution before filtering
figure;
histogram(blind_pass_table.accuracy,'BinEdges',1:1:100);
xlabel("accuracy");
ylabel("Frequency of appearence")
title("Raw blind pass accuracy distribution")
format_poster_fig();
exportgraphics(gcf, fullfile(local_figure_dir, 'unfiltered distribution of accuracies.pdf'), 'ContentType', 'vector', 'Resolution', 300,'BackgroundColor','none')

%% get the histogram for accuracy distribution after filtering
close all;figure;
histogram(rows_to_keep.accuracy,'BinEdges',1:1:100);
xlabel("accuracy");
ylabel("Frequency of appearence")
title("Filtered blind pass accuracy distribution")
ylim([0,600])
format_poster_fig();

exportgraphics(gcf, fullfile(local_figure_dir, 'filtered distribution of accuracies.pdf'), 'ContentType', 'vector', 'Resolution', 300,'BackgroundColor','none')

%% get a histogram of average abs distance to true accuracy
the_nans = isnan(estimated_accuracy);%id the nans which are cases we could not quantify reasonably

dist_to_true_accuracy = abs(blind_pass_table.accuracy(~the_nans) - estimated_accuracy(~the_nans));
median_distance = median(dist_to_true_accuracy);
histogram(dist_to_true_accuracy,'BinEdges',1:1:100);
xline(median_distance,"LineWidth",3,"Color","black","Label","Median Distance to true accuracy "+sprintf("%.2f",median_distance))
xlabel("Absolute distance from true accuracy");
ylabel("Frequency of appearence")
title("Filtered blind pass accuracy distribution")
format_poster_fig();
exportgraphics(gcf, fullfile(local_figure_dir, 'hist_of_dist_to_true_accuracy.pdf'), 'ContentType', 'vector', 'Resolution', 300,'BackgroundColor','none')