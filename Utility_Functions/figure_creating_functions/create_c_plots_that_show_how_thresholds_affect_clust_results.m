close all;clc;
[config,local_figure_dir] = set_up_figure_creation("name_of_calling_file",string(mfilename));
dir_of_poster_data = fullfile(config.data_dir,"data_for_poster_figs");
bp_2_ch = load(fullfile(dir_of_poster_data,"blind_pass_table_2_ch.mat"));
bp_2_ch = bp_2_ch.data_to_save;

config.GT_FP = fullfile(config.data_dir,"10_600Neuron300SecondRecordingWithLevel10Noise","ground_truth","ground_truth.mat");
config.ground_truth_cell_array = importdata(config.GT_FP);
config.ground_truth_cell_array = importdata(config.GT_FP);
config.TIMESTAMP_FP =  fullfile(config.data_dir,"1_600Neuron300SecondRecordingWithLevel1Noise","timestamps","timestamps.mat");
config.fp_to_table_of_best_rep = fullfile(config.data_dir,"rec_10_table_of_best_rep","table_of_best_rep.mat");
threshold_data = importdata(fullfile(dir_of_poster_data,"z_score_threshs_in_mv_for_rec_10.mat"));
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
only_desired_tetrodes = bp_2_ch(bp_2_ch.Tetrode == candidate_tetrodes(1),:);
current_channel_thresholds = cell2mat(threshold_data(only_desired_tetrodes{1,"channels"}{1}));
consistent_colors = distinguishable_colors(600);

tiledlayout(3,3,"TileSpacing","compact");
unique_z_scores = unique(only_desired_tetrodes.("Z Score"));
for i=1:length(unique_z_scores)
    f = figure;
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

        scatter(filtered_x(~is_tp), filtered_y(~is_tp), ...
            25, 'k', "x", 'LineWidth', 1, ...
            'DisplayName', "Cl" + string(j) + " FP");
        scatter(filtered_x(is_tp), filtered_y(is_tp), ...
            8, color_to_use, "o", 'filled', ...
            'DisplayName', "Cl" + string(j) + " TP");


    end
    title("Z score "+string(unique_z_scores(i)));
    % legend
    if i==1
        xlabel("Channel 1 Peaks (microvolts)");
        ylabel("Channel 2 Peaks (microvolts)");
        % legend('Location', 'northeastoutside');
    end
    format_for_illustrator_poster(gcf, ...
        Width=5, ...
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
    % ylim([-5,205])

end
% legend('Location','best');
