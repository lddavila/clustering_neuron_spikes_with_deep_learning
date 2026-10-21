close all;clc;
[config,fp_to_figs] = set_up_figure_creation();


dir_of_poster_data = fullfile(config.data_dir,"data_for_poster_figs");
config.GT_FP = fullfile(config.data_dir,"10_600Neuron300SecondRecordingWithLevel10Noise","ground_truth","ground_truth.mat");
config.ground_truth_cell_array = importdata(config.GT_FP);
config.TIMESTAMP_FP =  fullfile(config.data_dir,"1_600Neuron300SecondRecordingWithLevel1Noise","timestamps","timestamps.mat");
config.fp_to_table_of_best_rep = fullfile(config.data_dir,"rec_10_table_of_best_rep","table_of_best_rep.mat");
tetrodes_to_be_plotted = ["t1"];

threshold_data = importdata(fullfile(dir_of_poster_data,"z_score_threshs_in_mv_for_rec_10.mat"));


close all;
local_figure_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(fp_to_figs,"create_cluster_plots"));
only_desired_tetrodes = importdata(fullfile(dir_of_poster_data,"bp_2_ch_only_tetrode_1.mat"));
unique_z_scores = unique(only_desired_tetrodes.("Z Score"));
aligned = importdata(fullfile(dir_of_poster_data,"t1 aligned_to_peak_wf.mat"));
peaks = get_peaks(aligned,true);


close all;
current_channel_thresholds = cell2mat(threshold_data(only_desired_tetrodes{1,"channels"}{1}));
consistent_colors = distinguishable_colors(600);
f = figure;
tiledlayout(1,3,"TileSpacing","compact");
for i=1:3:length(unique_z_scores)
    nexttile();
    only_curr_z_score = only_desired_tetrodes(only_desired_tetrodes.("Z Score")==unique_z_scores(i),:);


    x_data = peaks(1,:);
    y_data = peaks(2,:);
    f_c1 = x_data > current_channel_thresholds(1,i) | y_data > current_channel_thresholds(2,i);
    scatter(x_data(f_c1),y_data(f_c1),3,[.7 .7 .7],'filled','DisplayName',"Unclustered")
    hold on;

    for j=1:height(only_curr_z_score)
        cluster_idx = only_curr_z_score{j,"cluster_idx"}{1};
        local_cluster_x_data = x_data(cluster_idx);
        local_cluster_y_data = y_data(cluster_idx);
        color_to_use = consistent_colors(only_curr_z_score{j,"Max_Overlap_Unit"},:);
        c1 = local_cluster_x_data > current_channel_thresholds(1,i) | local_cluster_y_data > current_channel_thresholds(2,i) ;
        scatter(local_cluster_x_data(c1),local_cluster_y_data(c1),3,color_to_use,'filled','DisplayName',"Cl"+string(j) +" U"+string(only_curr_z_score{j,"Max_Overlap_Unit"}))
    end
    title("Z score "+string(unique_z_scores(i)));
    if i==1
        xlabel("Channel 1 Peaks (microvolts)");
        ylabel("Channel 2 Peaks (microvolts)");
        legend('Location', 'northeastoutside'); 
    end
    ylim([-5,205])

end
% legend('Location','best');
format_for_illustrator_poster(gcf, ...
    Width=13, ...
    Height=5, ...
    Units="inches", ...
    FontName="Arial", ...
    TickFontSize=22.14, ...
    LabelFontSize=25.83, ...
    TitleFontSize=28, ...
    LegendFontSize=22.14, ...
    TextFontSize=22.14, ...
    TitleFontWeight="bold", ...
    AxesLineWidth=1.5, ...
    LineWidth=2, ...
    MarkerSize=8, ...
    Interpreter="none", ...
    Filename=fullfile(local_figure_dir,"Z score "+string(unique_z_scores(i))), ...
    Overwrite=true);