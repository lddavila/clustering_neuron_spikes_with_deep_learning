close all;clc;
[config,local_figure_dir] = set_up_figure_creation("name_of_calling_file",string(mfilename));
dir_of_poster_data = fullfile(config.data_dir,"data_for_poster_figs");

aligned = importdata(fullfile(dir_of_poster_data,"t1 aligned_to_peak_wf.mat"));
peaks = get_peaks(aligned,true);
load(fullfile(dir_of_poster_data,"t1.mat"),"r_tvals");
[the_min,the_max]= bounds(peaks,2);
all_the_max = max([the_min,the_max]);
pmv = compute_snr_statistic(aligned, aligned, r_tvals, all_the_max.');

percentiles = [1 20 40 60 80];
values = prctile(pmv(:), percentiles);

data = pmv(:);
data = data(isfinite(data));

percentiles = [0 20 40 60 80];
values = prctile(data, percentiles);
labels = ["Set 5: all data", "Set 4: >20%", "Set 3:>40%", "Set 2:>60%", "Set 1: >80%"];

% --- NEW COLOR STRATEGY MODIFICATION ---
% Define an RGB matrix for each of the 5 segments (one row per set)
colors = [
    0.25, 0.55, 0.70;  % Set 5 (0% to 20%) - Your original blue-grey
    0.30, 0.65, 0.50;  % Set 4 (20% to 40%)
    0.85, 0.65, 0.25;  % Set 3 (40% to 60%)
    0.85, 0.45, 0.25;  % Set 2 (60% to 80%)
    0.75, 0.25, 0.25   % Set 1 (>80%)
];

% 1. Determine common bin edges using 'fd' across all data to keep the bars aligned
global_h = histogram(data, 'BinMethod', 'fd');
common_edges = global_h.BinEdges;
delete(global_h); % Remove temporary placeholder

figure('Color', 'w');
hold on;

% 2. Plot segmented histograms using logical intervals
num_sets = numel(percentiles);
for idx = 1:num_sets
    % Filter data falling into the specific percentile range bracket
    lower_bound = values(idx);
    if idx < num_sets
        upper_bound = values(idx + 1);
        segmented_data = data(data >= lower_bound & data < upper_bound);
    else
        segmented_data = data(data >= lower_bound);
    end
    
    % Plot the segment matching the common structural edges
    histogram(segmented_data, ...
        'BinEdges', common_edges, ...
        'FaceColor', colors(idx, :), ...
        'EdgeColor', 'w', ...
        'FaceAlpha', 0.8,'DisplayName',"Set "+string(6 -idx));
end

% Keep your existing annotation boundaries loop intact
for k = 1:numel(percentiles)
    xline(values(k), '--', ...
        sprintf('%s: %.2f', labels(k), values(k)), ...
        'Color', 'black', ...
        'LineWidth', 3, ...
        'LabelOrientation', 'aligned', ...
        'LabelVerticalAlignment', 'top', ...
        'FontSize', 11,'HandleVisibility','off');
end
legend

format_for_illustrator_poster(gcf, ...
    Width=10, ...
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
    Filename=fullfile(local_figure_dir,"sample_pmv_aka_SNR.pdf"), ...
    Overwrite=true);
