% 1. Generate a mock waveform (Simulating a noisy signal with peaks)
close all;clc;
[config,local_figure_dir] = set_up_figure_creation("name_of_calling_file",string(mfilename));
channels_to_use = ["c1"];
dir_of_recordings = fullfile(config.data_dir,"data_for_poster_figs");
curr_ch_data = importdata(fullfile(dir_of_recordings,channels_to_use(1)+"_raw.mat"));
curr_ch_data = curr_ch_data * -1;
curr_peak_data = importdata(fullfile(dir_of_recordings,"c"+string(1)+"_peaks.mat"));
curr_pk_vals = curr_ch_data(curr_peak_data);
[~,highest_amp_peak ]= max(curr_pk_vals);
sample_peak = curr_peak_data(500);
waveform = curr_ch_data(sample_peak-15:1:sample_peak+29);
dir_of_poster_data = fullfile(config.data_dir,"data_for_poster_figs");
% waveform = 3*exp(-((t - 3)/0.4).^2) + 5*exp(-((t - 6)/0.8).^2) + 0.2*sin(5*t);

% 2. Retrieve peak data numerically
% pks = heights, locs = x-positions, w = widths, p = prominences
[pks, locs, w, p] = findpeaks(waveform, 'MinPeakProminence', 100.0,'MinPeakDistance',30);

% 3. Calculate Peak-to-Height Ratio
% Depending on your definition, this is either Prominence/Height or Width/Height.
% We will use Prominence-to-Height Ratio here.
p_to_h_ratio = p ./ pks;

% 4. Create the plot and visually indicate Peak Prominence and Width
figure;
findpeaks(waveform, 'Annotate', 'extents', 'MinPeakProminence', 100.0);
hold on;

%5. Add custom annotations for the Peak-to-Height Ratio
for i = 1:length(pks)
    textStr = sprintf('P/H Ratio: %.2f', p_to_h_ratio(i));
    % Position the text slightly above and to the right of each peak
    text(locs(i) + 0.1, pks(i) + 0.2, textStr, 'Color', 'black', 'FontSize', 9, 'FontWeight', 'bold');
end
legend('off')
% Polish the graph layout
% title('Waveform Analysis: Prominence, Width, and Peak-to-Height Ratio');
% xlabel('number of sampled data');
% ylabel('Amplitude');
hold off;

format_for_illustrator_poster(gcf, ...
    Width=10, ...
    Height=10, ...
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
    Filename=fullfile(local_figure_dir,"sample_spike.pdf"), ...
    Overwrite=true);
