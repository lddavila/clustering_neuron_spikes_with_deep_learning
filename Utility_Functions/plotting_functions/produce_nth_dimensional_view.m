function [img_gray]= produce_nth_dimensional_view(spikes, channels)
% Returns a 200x300 grayscale image of all 2D projections in a tight grid.

% Invisible figure, exact pixel size
f = figure('Visible','off', 'Units','pixels', 'Position',[100 100 300 200], ...
           'Color','white');  % opengl handles scatter well

all_pairs = nchoosek(1:numel(channels), 2);
nPlots    = size(all_pairs,1);
nRows     = ceil(sqrt(nPlots));
nCols     = ceil(nPlots/nRows);

t = tiledlayout(f, nRows, nCols, 'Padding','none', 'TileSpacing','none');

for i = 1:nPlots
    ax = nexttile(t);
    dim1 = all_pairs(i,1);
    dim2 = all_pairs(i,2);

    s1 = squeeze(spikes(dim1,:,:));
    s1 = max(s1,[],2);

    s2 = squeeze(spikes(dim2,:,:));
    s2 = max(s2,[],2);

    % Use a slightly larger marker and a dot glyph for visibility after downsampling
    scatter(ax, s1, s2, 4, 'k', '.');   % was size=1; dot marker keeps it crisp
    axis(ax, 'tight'); axis(ax, 'off');
    set(ax, 'Color','white');           % white axes background
end

drawnow;                 % ensure everything is rendered
frame   = getframe(f);   % capture the WHOLE figure (all tiles)
img_rgb = frame.cdata;   % uint8 HxWx3
close(f);

% Ensure exact 200x300 in case OS scaled the window
img_rgb  = imresize(img_rgb, [200 300], 'nearest');  % preserve dots better
img_gray = rgb2gray(img_rgb);
%figure;
%imshow(img_gray);
end