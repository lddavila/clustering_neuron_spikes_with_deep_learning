function fig = format_for_illustrator_poster(fig, options)
%FORMAT_FOR_ILLUSTRATOR Format an existing figure and optionally export PDF.
% MATLAB R2023b. Modifies the supplied figure in place; call after plotting.
%
% format_for_illustrator(gcf)
% format_for_illustrator(gcf, Width=6, Height=6, Filename="panel.pdf")
% format_for_illustrator(gcf, Width=18, Height=15, Units="centimeters", ...
%     TickFontSize=22, LabelFontSize=26, TitleFontSize=28)
%
% Width/Height: TOTAL PDF page size, including labels and whitespace.
% All font sizes, LineWidth, AxesLineWidth and MarkerSize are in POINTS.
% ScatterSize is marker AREA in points squared. Empty optional values keep
% the existing setting. Filename="" formats without exporting.
%
% Defaults emulate the supplied 60-by-42-inch poster's plot typography.
% Blue section headings are normally added separately in Illustrator.
%
% OPTIONS (name=value):
% Width=6, Height=6, Units="inches" (also "centimeters" or "points")
% FontName="Arial", TickFontSize=22.14, LabelFontSize=25.83,
% TitleFontSize=25.83, LegendFontSize=22.14, TextFontSize=22.14
% TitleFontWeight="normal", TitleFontAngle="normal"
% AxesLineWidth=1.5, LineWidth=[], MarkerSize=[], ScatterSize=[]
% Interpreter="preserve" (or "none", "tex", "latex")
% BackgroundColor=[1 1 1], AxesColor=[] (preserve axes backgrounds)
% Margins=[] or [left bottom right top], in Units. Only for ONE ordinary
% Cartesian axes directly parented by the figure, without legend/colorbar.
% For subplots/tiledlayout, leave Margins=[] and retain the layout manager.
% Filename="" (PDF only), Overwrite=false
%
% Notes:
% - Supports standard Cartesian plots, subplots and tiledlayout. Specialized
%   charts (heatmap, geographic/polar axes, UI figures) are not targeted.
% - Layout titles/labels receive TextFontSize unless overridden afterward.
% - Font settings cannot override explicit TeX font commands or LaTeX fonts.
% - Painters preserves vector-capable content; images remain raster images,
%   and transparency/complex 3-D content may not reproduce identically.
% - Open/place the PDF at 100%% scale in Illustrator. Use its full page box
%   when checking dimensions; visible artwork can have smaller bounds.
% - Check labels visually after formatting, especially at small sizes.

arguments
    fig (1,1) matlab.ui.Figure
    options.Width (1,1) double {mustBePositive,mustBeFinite} = 6
    options.Height (1,1) double {mustBePositive,mustBeFinite} = 6
    options.Units (1,1) string {mustBeMember(options.Units,["inches","centimeters","points"])} = "inches"
    options.FontName (1,1) string = "Arial"
    options.TickFontSize (1,1) double {mustBePositive,mustBeFinite} = 22.14
    options.LabelFontSize (1,1) double {mustBePositive,mustBeFinite} = 25.83
    options.TitleFontSize (1,1) double {mustBePositive,mustBeFinite} = 25.83
    options.LegendFontSize (1,1) double {mustBePositive,mustBeFinite} = 22.14
    options.TextFontSize (1,1) double {mustBePositive,mustBeFinite} = 22.14
    options.TitleFontWeight (1,1) string {mustBeMember(options.TitleFontWeight,["normal","bold"])} = "normal"
    options.TitleFontAngle (1,1) string {mustBeMember(options.TitleFontAngle,["normal","italic"])} = "normal"
    options.AxesLineWidth (1,1) double {mustBePositive,mustBeFinite} = 1.5
    options.LineWidth double = []
    options.MarkerSize double = []
    options.ScatterSize double = []
    options.Interpreter (1,1) string {mustBeMember(options.Interpreter,["preserve","none","tex","latex"])} = "preserve"
    options.BackgroundColor (1,3) double = [1 1 1]
    options.AxesColor double = []
    options.Margins double = []
    options.Filename (1,1) string = ""
    options.Overwrite (1,1) logical = false
end

% Validate optional settings before modifying anything.
for name = ["LineWidth","MarkerSize","ScatterSize"]
    value = options.(name);
    if ~isempty(value)
        validateattributes(value, {'double'}, {'scalar','positive','finite'}, mfilename, char(name));
    end
end
validateattributes(options.BackgroundColor, {'double'}, {'>=',0,'<=',1,'finite'});
if ~isempty(options.AxesColor)
    validateattributes(options.AxesColor, {'double'}, {'size',[1 3],'>=',0,'<=',1,'finite'});
end
ax = findall(fig, 'Type','axes');
if ~isempty(options.Margins)
    validateattributes(options.Margins, {'double'}, {'size',[1 4],'nonnegative','finite'});
    m = options.Margins;
    if numel(ax) ~= 1 || ~isequal(ax.Parent,fig) || ...
            ~isempty(findall(fig,'Type','legend')) || ~isempty(findall(fig,'Type','colorbar'))
        error('format_for_illustrator:MarginsLayout', ...
            'Margins requires one axes directly in the figure, with no legend or colorbar.');
    end
    if m(1)+m(3) >= options.Width || m(2)+m(4) >= options.Height
        error('format_for_illustrator:MarginsSize','Margins leave no plotting area.');
    end
end
filename = options.Filename;
if strlength(filename) > 0
    [folder,~,ext] = fileparts(filename);
    if ext == ""
        filename = filename + ".pdf";
    elseif ~strcmpi(ext,'.pdf')
        error('format_for_illustrator:FileType','Filename must have a .pdf extension.');
    end
    if strlength(folder) > 0 && ~isfolder(folder)
        error('format_for_illustrator:Folder','Output folder does not exist: %s',folder);
    end
    if isfile(filename) && ~options.Overwrite
        error('format_for_illustrator:Exists','File exists. Set Overwrite=true to replace it.');
    end
end

% CRITICAL FOR EDITABLE TEXT: Force vector text mapping behavior
set(fig, 'Renderer', 'painters');

fig.WindowStyle = 'normal';
fig.WindowState = 'normal';
fig.Units = char(options.Units);
position = fig.Position;
position(3:4) = [options.Width options.Height];
fig.Position = position;
fig.Color = options.BackgroundColor;
fig.InvertHardcopy = 'off';

% General text first; specific labels, titles and legends override below.
objects = findall(fig, '-property','FontSize');
for k = 1:numel(objects)
    h = objects(k);
    if isprop(h,'FontUnits'), h.FontUnits = 'points'; end
    if isprop(h,'FontName'), h.FontName = char(options.FontName); end
    h.FontSize = options.TextFontSize;
end
if options.Interpreter ~= "preserve"
    set(findall(fig,'-property','Interpreter'), 'Interpreter',char(options.Interpreter));
    set(findall(fig,'-property','TickLabelInterpreter'), ...
        'TickLabelInterpreter',char(options.Interpreter));
end
for k = 1:numel(ax)
    a = ax(k);
    axis(a, 'square');
    % Show ticks only at the minimum and maximum of each axis
    a.XTick = a.XLim;
    a.YTick = a.YLim;
    a.FontUnits = 'points';
    a.FontSize = options.TickFontSize;
    a.LineWidth = options.AxesLineWidth;
    if ~isempty(options.AxesColor), a.Color = options.AxesColor; end
    set([a.XLabel a.YLabel a.ZLabel], 'FontUnits','points', ...
        'FontSize',options.LabelFontSize);
    set(a.Title, 'FontUnits','points', 'FontSize',options.TitleFontSize, ...
        'FontWeight',char(options.TitleFontWeight), ...
        'FontAngle',char(options.TitleFontAngle));
end
set(findall(fig,'Type','legend'), 'FontSize',options.LegendFontSize);
cb = findall(fig,'Type','colorbar');
for k = 1:numel(cb)
    cb(k).FontSize = options.TickFontSize;
    cb(k).Label.FontSize = options.LabelFontSize;
end
% Change data objects only, not axes/legend borders.
if ~isempty(options.LineWidth)
    for type = ["line","scatter","bar","errorbar","stair","stem"]
        set(findall(fig,'Type',char(type),'-property','LineWidth'), ...
            'LineWidth',options.LineWidth);
    end
end
if ~isempty(options.MarkerSize)
    set(findall(fig,'-property','MarkerSize'),'MarkerSize',options.MarkerSize);
end
if ~isempty(options.ScatterSize)
    set(findall(fig,'Type','scatter'),'SizeData',options.ScatterSize);
end

drawnow;
if ~isempty(options.Margins)
    ax.Units = char(options.Units);
    ax.PositionConstraint = 'innerposition';
    ax.Position = [m(1) m(2) options.Width-m(1)-m(3) options.Height-m(2)-m(4)];
    drawnow;
    ti = ax.TightInset;
    if any(ti > m)
        warning('format_for_illustrator:SmallMargins', ...
            'Some margins are smaller than the label extents; check for clipped labels.');
    end
end

% Force hardcopy dimensions to explicitly match requested size
% Set exact PDF page dimensions, including labels and whitespace.
fig.PaperUnits = char(options.Units);
fig.PaperSize = [options.Width options.Height];
fig.PaperPosition = [0 0 options.Width options.Height];
fig.PaperPositionMode = 'manual';

drawnow;

% Export using the specified page dimensions.
if strlength(filename) > 0
    print(fig, char(filename), '-dpdf', '-painters');
end

end
