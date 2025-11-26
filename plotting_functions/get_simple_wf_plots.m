function [fp_array] = get_simple_wf_plots(left_mean_wf_cell_array,right_mean_wf_cell_array,dir_to_save_training_images_to)
% Invisible figure, exact pixel size
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations =size(left_mean_wf_cell_array{1},1);
print_status_bar(num_iterations,"get_simple_wf_plots.m")
fp_array = repelem("",size(right_mean_wf_cell_array{1},1),1);
parfor i = 1:size(right_mean_wf_cell_array{1},1)
    f = figure('Visible','off','Units','pixels','Position',[100 100 300 450]);

    nRows = length(left_mean_wf_cell_array);
    t = tiledlayout(f, nRows, 1, 'Padding','none', 'TileSpacing','none');
    save_name = "mean_wf_"+string(i)+".png";
    fp_array(i) = fullfile(fullfile(dir_to_save_training_images_to,save_name));
    if isfile(fullfile(dir_to_save_training_images_to,save_name))
        send(q,[]);
        continue;
    end
    
    for j=1:length(right_mean_wf_cell_array)
        ax = nexttile(t);
        s1 =left_mean_wf_cell_array{j}(i,:);
        s2 = right_mean_wf_cell_array{j}(i,:);
        % Use a slightly larger marker and a dot glyph for visibility after downsampling
        plot(ax, s1,'Color','k','LineWidth',1);   % was size=1; dot marker keeps it crisp
        hold on;
        plot(ax,s2,'Color','k','LineWidth',1);
        axis(ax, 'tight'); axis(ax, 'off');
        set(ax, 'Color','white');           % white axes background
    end
    frame   = getframe(f);   % capture the WHOLE figure (all tiles)
    img_rgb = frame.cdata;   % uint8 HxWx3

    % Ensure exact 200x300 in case OS scaled the window
    %img_rgb  = imresize(img_rgb, [400 100], 'nearest');  % preserve dots better
    img_gray = rgb2gray(img_rgb);
    par_save_as_jpeg(fullfile(dir_to_save_training_images_to,save_name),img_gray)
    send(q,[]);
end



end