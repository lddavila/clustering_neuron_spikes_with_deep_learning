close all;clc;
[config,fp_to_figs] = set_up_figure_creation("name_of_calling_file","create_poster_parameters_panel");
dir_of_poster_data = fullfile(config.data_dir,"data_for_poster_figs");
bp_2_ch = load(fullfile(dir_of_poster_data,"blind_pass_table_2_ch.mat"));
bp_2_ch = bp_2_ch.data_to_save;

config.GT_FP = fullfile(config.data_dir,"10_600Neuron300SecondRecordingWithLevel10Noise","ground_truth","ground_truth.mat");
config.ground_truth_cell_array = importdata(config.GT_FP);
config.ground_truth_cell_array = importdata(config.GT_FP);
config.TIMESTAMP_FP =  fullfile(config.data_dir,"1_600Neuron300SecondRecordingWithLevel1Noise","timestamps","timestamps.mat");
config.fp_to_table_of_best_rep = fullfile(config.data_dir,"rec_10_table_of_best_rep","table_of_best_rep.mat");

timestamps = importdata(config.TIMESTAMP_FP);
%% for each tetrode find if there's a cluster/unit that only appears on a
% single level and disappears on others
unique_tetrode = unique(bp_2_ch.Tetrode);
candidate_tetrodes = [];
for i=1:length(unique_tetrode)
    only_curr_tetrode = bp_2_ch(bp_2_ch.Tetrode==unique_tetrode(i) & bp_2_ch.accuracy > 40,:);
    unique_units = unique(only_curr_tetrode.Max_Overlap_Unit);
    for j=1:length(unique_units)
        only_current_unit = only_curr_tetrode(only_curr_tetrode.Max_Overlap_Unit==unique_units(j),:);
        local_z_scores = unique(only_current_unit.("Z Score"));
        if length(local_z_scores)==1
            candidate_tetrodes = [candidate_tetrodes,only_curr_tetrode{1,"Tetrode"}];
        end
    end
    fprintf("Finished %i / %i\n",i,length(unique_tetrode))
end


aligned = importdata(fullfile(dir_of_poster_data,candidate_tetrodes(1)+" aligned_to_peak_wf.mat"));
peaks = get_peaks(aligned,true);

%%
close all;
threshold_data = importdata(fullfile(dir_of_poster_data,"z_score_threshs_in_mv_for_rec_10.mat"));
% threshold_data = importdata(fullfile(,"z_score_threshs_in_mv_for_rec_10.mat"));
only_desired_tetrodes = bp_2_ch(bp_2_ch.Tetrode == candidate_tetrodes(1),:);
current_channel_thresholds = cell2mat(threshold_data(only_desired_tetrodes{1,"channels"}{1}));
consistent_colors = distinguishable_colors(600);

unique_z_scores = unique(only_desired_tetrodes.("Z Score"));


channels_to_use = ["c1_raw.mat","c2_raw.mat"];

starting_plotting_point = 1500;
time_delta = 1/30000;
number_of_dpts_to_plot = 300;
end_time = (starting_plotting_point+number_of_dpts_to_plot - 1) * time_delta;

local_figure_dir = fp_to_figs;

x_data = linspace(starting_plotting_point * time_delta, end_time, number_of_dpts_to_plot+1);

% legend_string =["channel 1","channel 1 peaks","channel 2","channel 2 peaks"];
colors_to_use = distinguishable_colors(length(channels_to_use));
range_to_plot =starting_plotting_point:starting_plotting_point+ number_of_dpts_to_plot ;
f = figure('units','normalized','outerposition',[0 0 1 1]);
tiledlayout(2,2,"TileSpacing","compact");
nexttile();
for i=1:1.5
    curr_ch_data = importdata(fullfile(dir_of_poster_data,channels_to_use(i)));
    in_range_ch = curr_ch_data(range_to_plot);
    curr_peak_data = importdata(fullfile(dir_of_poster_data,"c"+string(i)+"_peaks.mat"));
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

    format_poster_fig();

end
%
unique_z_scores = [3,4,6];
current_channel_thresholds = [threshold_data{1};threshold_data{2}];
for i=1:length(unique_z_scores)
    only_curr_z_score = only_desired_tetrodes(only_desired_tetrodes.("Z Score")==unique_z_scores(i),:);
    x_data = peaks(1,:);
    y_data = peaks(2,:);
    f_c1 = x_data > current_channel_thresholds(1,i) | y_data > current_channel_thresholds(2,i);
    nexttile();
    scatter(x_data(f_c1),y_data(f_c1),3,[.7 .7 .7],'filled','DisplayName',"Unclustered")
    hold on;

    for j=1:height(only_curr_z_score)
        cluster_idx = only_curr_z_score{j,"cluster_idx"}{1};
        local_cluster_x_data = x_data(cluster_idx);
        local_cluster_y_data = y_data(cluster_idx);
        color_to_use = consistent_colors(only_curr_z_score{j,"Max_Overlap_Unit"},:);

        above_threshold = ...
            local_cluster_x_data(:) > current_channel_thresholds(1,i) | ...
            local_cluster_y_data(:) > current_channel_thresholds(2,i);

        the_cluster_ts = only_curr_z_score{j,"timestamps"}{1};

        % Keep coordinates and timestamps aligned.
        filtered_x = local_cluster_x_data(above_threshold);
        filtered_y = local_cluster_y_data(above_threshold);
        filtered_ts = the_cluster_ts(above_threshold);

        is_tp = logical(get_map_of_tp_fp_tn_for_a_cluster( ...
            config.ground_truth_cell_array, ...
            only_curr_z_score{j,"Max_Overlap_Unit"}, ...
            filtered_ts, timestamps, 0.0002));

        if i==1 && j==1
            scatter(filtered_x(~is_tp), filtered_y(~is_tp), ...
                25, 'k', "x", 'LineWidth', 1, ...
                'DisplayName', " FP");
        else
            scatter(filtered_x(~is_tp), filtered_y(~is_tp), ...
                25, 'k', "x", 'LineWidth', 1, ...
                'HandleVisibility','off');
        end
        scatter(filtered_x(is_tp), filtered_y(is_tp), ...
            8, color_to_use, "o", 'filled', ...
            'DisplayName', "Cl" + string(j) + " TP");


    end
    title("Z score "+string(unique_z_scores(i)));
    % legend
    if i==1
        xlabel("Channel 1 Peaks (microvolts)");
        ylabel("Channel 2 Peaks (microvolts)");
        legend('Location', 'best');
    end
    format_poster_fig;
end
% set(gcf, 'Renderer', 'painters');

% Export using the print command
% print(gcf, fullfile(local_figure_dir, 'my_plot.pdf'), '-dsvg');
exportgraphics(gcf, fullfile(local_figure_dir, 'parameters_panel.pdf'), 'ContentType', 'vector','Resolution', 300,'BackgroundColor','none')
% legend('Location','best');
