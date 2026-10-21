function [] = remove_tics(options)
arguments
    options.figure_to_format = []
    options.remove_x = true;
    options.remove_y = true;
end
if ~isempty(options.figure_to_format)
    figure(options.figure_to_format)
else
    gcf();
end
try
xt = xticks();
if options.remove_x
    xticks([xt(1), xt(end)]);
end
% Keep only the first and last Y-axis tick marks
yt = yticks();
if options.remove_y
    yticks([yt(1), yt(end)]);
end
catch
end
end