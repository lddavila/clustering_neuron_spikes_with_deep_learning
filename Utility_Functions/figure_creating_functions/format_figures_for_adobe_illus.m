function [] = format_figures_for_adobe_illus(figHandle, pointSize, figLetter, figTitleText, paper_or_poster)
% FORMATJOURNALFIGURE Formats a MATLAB figure to strict journal specifications.
%
% Inputs:
%   figHandle    - Handle to the figure (e.g., gcf)
%   pointSize    - 'main', 'medium', or 'small' (determines width)
%   figLetter    - String/Char for the figure letter (e.g., 'A', 'a')
%   figTitleText - String/Char for the figure title description
if paper_or_poster=="paper"
    % Ensure the figure is active
    figure(figHandle);
    ax = gca;

    % 1. Figure Size & Dimensions (Vertical size is always 2 inches)
    figHandle.Units = 'inches';
    switch lower(pointSize)
        % Width x Height
        case 'main'
            figHandle.Position =[1,1, 2,2];   % 2x2 inch
        case 'medium'
            figHandle.Position = [1, 1, 1.5, 2]; % 1.5x2 inch
        case 'small'
            figHandle.Position =[1,1,1,2];   % 1x2 inch
        otherwise
            error('pointSize must be ''main'', ''medium'', or ''small''');
    end

    % 2. Axis Properties (Thickness, Color, and Ticks)
    ax.LineWidth = 0.5;         % Axis thickness: 0.5
    ax.XColor = [0 0 0];        % Color: Black
    ax.YColor = [0 0 0];        % Color: Black
    ax.Box = 'on';              % Keeps full border box matching your specs

    % Force tick marks only at the exact beginning and end of the lines
    ax.XTick = [ax.XLim(1), ax.XLim(2)];
    ax.YTick = [ax.YLim(1), ax.YLim(2)];

    % 3. Typography (Font Sizes & Styles)
    % Numbers accompanying tick marks: Arial 6
    ax.FontName = 'Arial';
    ax.FontSize = 6;

    % Axis Labels: Arial 7
    ax.XLabel.FontName = 'Arial';
    ax.XLabel.FontSize = 7;
    ax.YLabel.FontName = 'Arial';
    ax.YLabel.FontSize = 7;

    % Format Axis Labels to sentence case (only first letter capital)
    if ~isempty(ax.XLabel.String)
        ax.XLabel.String = lower(ax.XLabel.String);
        ax.XLabel.String(1) = upper(ax.XLabel.String(1));
    end
    if ~isempty(ax.YLabel.String)
        ax.YLabel.String = lower(ax.YLabel.String);
        ax.YLabel.String(1) = upper(ax.YLabel.String(1));
    end

    % Legend: Arial 5 (if legend exists)
    leg = findobj(figHandle, 'Type', 'Legend');
    if ~isempty(leg)
        leg.FontName = 'Arial';
        leg.FontSize = 5;
    end

    % 4. Integrated Journal Header (Figure Letter & Title in Gray Box)
    % Clears standard title to use the specialized top banner layout instead
    title('');

    % Enforce sentence case for the input title string
    if ~isempty(figTitleText)
        figTitleText = lower(figTitleText);
        figTitleText(1) = upper(figTitleText(1));
    end

    % Create full text string: Bold Letter followed by normal Title text
    fullHeaderText = sprintf('\\bf{%s}\\rm  %s', figLetter, figTitleText);

    % Create an annotation text box spanning the top width of the 2-inch tall figure
    annotation(figHandle, 'textbox', ...
        [0, 0.85, 1, 0.15], ...               % [Left, Bottom, Width, Height] normalized
        'String', fullHeaderText, ...
        'FontName', 'Arial', ...
        'FontSize', 7, ...                    % Title font size: Arial 7
        'BackgroundColor', [0.9 0.9 0.9], ... % Gray box background
        'EdgeColor', 'none', ...              % Remove border around gray box
        'VerticalAlignment', 'middle', ...
        'HorizontalAlignment', 'center', ...
        'Interpreter', 'tex');                % Allows bolding (\bf) of just the

else
    % Ensure the figure is active
    figure(figHandle);
    ax = gca;
    ax.Units = 'normalized';
    ax.PositionConstraint = 'outerposition';
    ax.Position = [0 0 1 1];

    % 1. Figure Size & Dimensions (Vertical size is always 2 inches)
    figHandle.Units = 'inches';
    ax.Units = 'inches';
    ax.PositionConstraint = 'innerposition';
    switch lower(pointSize)
        % Width x Height
        case 'small'
            %ax.Position =[1,1, 2,5];   % 2x5 inch
            figHandle.Position = [1,1,2,5];
        case 'medium'
            %ax.Position = [1, 1, 5, 10]; % 5x15 inch
             figHandle.Position = [1,1,5,10];
        case 'main'
            %ax.Position =[1,1,6,15];   % 6x15 inch
             figHandle.Position = [1,1,6,15];
        otherwise
            error('pointSize must be ''main'', ''medium'', or ''small''');
    end

    % 2. Axis Properties (Thickness, Color, and Ticks)
    ax.LineWidth = 4.32;         % Axis thickness: 0.5
    ax.XColor = [0 0 0];        % Color: Black
    ax.YColor = [0 0 0];        % Color: Black
    ax.Box = 'on';              % Keeps full border box matching your specs

    % Force tick marks only at the exact beginning and end of the lines
    ax.XTick = [ax.XLim(1), ax.XLim(2)];
    ax.YTick = [ax.YLim(1), ax.YLim(2)];

    % 3. Typography (Font Sizes & Styles)
    % Numbers accompanying tick marks: Arial 6
    ax.FontName = 'Arial';
    ax.FontSize = 22.14;

    % Axis Labels: Arial 7
    ax.XLabel.FontName = 'Arial';
    ax.XLabel.FontSize = 25.83;
    ax.YLabel.FontName = 'Arial';
    ax.YLabel.FontSize = 25.83;

    % Format Axis Labels to sentence case (only first letter capital)
    if ~isempty(ax.XLabel.String)
        ax.XLabel.String = lower(ax.XLabel.String);
        ax.XLabel.String(1) = upper(ax.XLabel.String(1));
    end
    if ~isempty(ax.YLabel.String)
        ax.YLabel.String = lower(ax.YLabel.String);
        ax.YLabel.String(1) = upper(ax.YLabel.String(1));
    end

    % Legend: Arial 5 (if legend exists)
    leg = findobj(figHandle, 'Type', 'Legend');
    if ~isempty(leg)
        leg.FontName = 'Arial';
        leg.FontSize = 22.14;
    end

    % 4. Integrated Journal Header (Figure Letter & Title in Gray Box)
    % Clears standard title to use the specialized top banner layout instead
    title('');

    % Enforce sentence case for the input title string
    if ~isempty(figTitleText)
        figTitleText = lower(figTitleText);
        figTitleText(1) = upper(figTitleText(1));
    end

    % Create full text string: Bold Letter followed by normal Title text
    % fullHeaderText = sprintf('\\bf{%s}\\rm  %s', figLetter, figTitleText);


end
set(gcf, 'Renderer', 'painters')
end