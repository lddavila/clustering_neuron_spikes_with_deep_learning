%add dots to the peaks
%add threshold lines to the plots

close all;
[config,fp_to_figs] = set_up_figure_creation();

dir_of_recordings = fullfile(config.data_dir,"data_for_poster_figs");
threshold_data = importdata(fullfile(dir_of_recordings,"z_score_threshs_in_mv_for_rec_10.mat"));
channels_to_use = ["c1_raw.mat","c2_raw.mat"];

starting_plotting_point = 1500;
time_delta = 1/30000;
number_of_dpts_to_plot = 300;
end_time = (starting_plotting_point+number_of_dpts_to_plot - 1) * time_delta;

local_figure_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(fp_to_figs,"create_waveform_plots"));

x_data = linspace(starting_plotting_point * time_delta, end_time, number_of_dpts_to_plot+1);

% legend_string =["channel 1","channel 1 peaks","channel 2","channel 2 peaks"];
colors_to_use = distinguishable_colors(length(channels_to_use));
range_to_plot =starting_plotting_point:starting_plotting_point+ number_of_dpts_to_plot ;
for i=1:1.5;length(channels_to_use)
    f = figure('units','normalized','outerposition',[0 0 1 1]);
    curr_ch_data = importdata(fullfile(dir_of_recordings,channels_to_use(i)));
    in_range_ch = curr_ch_data(range_to_plot);
    curr_peak_data = importdata(fullfile(dir_of_recordings,"c"+string(i)+"_peaks.mat"));
    peaks_in_range = (curr_peak_data(curr_peak_data<number_of_dpts_to_plot+starting_plotting_point & curr_peak_data > starting_plotting_point)) - (starting_plotting_point-1);
    ax = plot(x_data,in_range_ch * -1,'LineWidth',2,'Color',colors_to_use(i,:),'DisplayName',"Channel "+string(i));
    y_data_for_peaks = curr_ch_data(peaks_in_range+starting_plotting_point-1);
    hold on;
    scatter(x_data(peaks_in_range).',y_data_for_peaks *-1,50,colors_to_use(i,:),'filled','DisplayName',"Peaks");
    current_channel_thresholds = threshold_data{i};
    for j=1:3:length(current_channel_thresholds)
        yline(current_channel_thresholds(j),'Label',sprintf("Threshold in Microvolts %.2f, in z-score %i",current_channel_thresholds(j),j+2),'Color',colors_to_use(i,:),'HandleVisibility','off','LineStyle','--','LabelHorizontalAlignment','center')
    end
    legend('Location','best')
    ylabel("(inverted) microvolts");
    xlabel("Time (s)")

    format_for_illustrator_poster(gcf, ...
        Width=9, ...
        Height=9, ...
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
        Filename=fullfile(local_figure_dir,"Channel "+string(i)+".pdf"), ...
        Overwrite=true);

end



% save_plots_in_all_formats(f,);