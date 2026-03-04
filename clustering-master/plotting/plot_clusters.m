%edited by Luis David Davila and Alexander Friedman
function plot_clusters(the_cluster_filters, the_raw_data, the_tvals, the_inputrange, the_gradings, the_together)
%PLOT_CLUSTERS Plots clusters in the peak feature projects
    individually = false;
    plot_all = true;
    if nargin == 4
        the_gradings = [];
        the_together = true;
    elseif nargin == 5
        the_together = false;
        individually = true;
        if strcmpi(the_gradings, 'all')
            plot_all = true;
        end
    end

    colors = distinguishable_colors(length(the_cluster_filters)+10);
    red = [0 0 0];
    myplot = @(x, y, c) plot(x, y, 'Color', c, 'LineStyle', 'none', 'Marker', 'o', 'MarkerSize', 5,'MarkerFaceColor',c,'MarkerEdgeColor',c);
    
    dimension_names = ["1st Wire peak(voltage)","2nd Wire Peak (Voltage)","3rd Wire Peak (Voltage)","4th Wire Peak (Voltage)",...
        "Wire 1 PC1","Wire 2 PC2","Wire 3 PC3","Wire 4 PC4",...
        "Wire 1 Peak PC1","Wire 2 Peak PC2","Wire 3 Peak PC3"];
    if length(the_cluster_filters) > length(colors)
        warning('plot_clusters:toomanyclusters', 'Need more colors to plot all the clusters')
        the_cluster_filters = the_cluster_filters(1:length(colors));
    end
    %     peaks = max(raw, [], 3);
    peaks = get_peaks(the_raw_data, false, the_tvals, the_inputrange);
    data = peaks';

    % data = extract_cluster_features_ver_2(raw);

    % Perform space transformation on normalized data
        weighted_data = resized_data .* repmat(weights, size(resized_data, 1), 1);

    %     peaks = rotatefactors(peaks', 'method', 'promax')';
    % pcs = get_new_pcs(raw);
    % pc1 = pcs(:,:,1)';
    %     peaks2 = max(abs(fft(raw, [], 3)), [], 3);
    % [~, peakpcs] = pca(peaks');
    % num_peaks = size(peaks,1);
    % cluster_data = zscore([peaks.' ; pc1 ; peakpcs(:, 1:num_peaks-1)']');

    %     data = zscore(data);
    % data = cluster_data;
    ratings = rate_clusters(the_cluster_filters, data);

    pairs = [];
    for i=1:size(data,2)
        for j=i+1:size(data,2)
            pairs = [pairs;i,j];
        end
    end

    if plot_all
        % pairs = [1 2; 1 3; 1 4; 2 3; 2 4; 3 4];
        ir = max(the_inputrange);
        figure
        % set(gcf, 'Visible', 'off')
        for k = 1:size(pairs, 1)
            figure;
            % set(gca, 'Color', 'k')
            x_axis = pairs(k, 1);
            y_axis = pairs(k, 2);
            hold on
%             xlim([0 ir]);
%             ylim([0 ir]);
            % myplot(data(:, x_axis), data(:, y_axis), red) %seems to plot all the data
            legend_array = cell(1,size(the_cluster_filters,1)+1);
            % legend_array{1} = "All Data: "+ string(size(data,1))+ " Spikes";
            all_clustered_indexes = [];
            for c = 1:length(the_cluster_filters) %this for loop plots the clusters one at a time
                legend_array{c} = "C" + string(c) + " # of spikes:"+ string(size(the_cluster_filters{c},1));
                cluster = data(the_cluster_filters{c}, :);
                cluster_x = cluster(:, x_axis);
                cluster_y = cluster(:, y_axis);
                myplot(cluster_x, cluster_y, colors(c,:))
                all_clustered_indexes = [all_clustered_indexes,the_cluster_filters{c}.'];
            end
            all_data_indexes = 1:size(data,1);
            all_unclustered_indexes = setdiff(all_data_indexes,all_clustered_indexes);

            myplot(data(all_unclustered_indexes,x_axis),data(all_unclustered_indexes,y_axis),colors(c+1,:));
            legend_array{end} = "Unclustered Spikes: " + string(length(all_unclustered_indexes));
            xlabel(dimension_names(x_axis))
            ylabel(dimension_names(y_axis))
            legend(legend_array,'Location','best')
            hold off
        end
        % set(gcf, 'Visible', 'on')
        set(gcf, 'InvertHardCopy', 'off')
    elseif individually
        for c = 1:length(the_cluster_filters)
            rating = ratings(:, c);
            [~, inds] = sort(rating);
            x_axis = inds(1);
            y_axis = inds(2);
            
            figure
            set(gcf, 'Visible', 'off')
            hold on
            
            xlim([0 the_inputrange(x_axis)]);
            ylim([0 the_inputrange(y_axis)]);
            data_x = data(:, x_axis);
            data_y = data(:, y_axis);
            myplot(data_x, data_y, red)
            if the_together
                cluster_vec = 1:length(the_cluster_filters);
            else
                cluster_vec = c;
            end
            for d = cluster_vec
                cluster = the_cluster_filters{d};
                cluster_x = data_x(cluster);
                cluster_y = data_y(cluster);
                myplot(cluster_x, cluster_y, colors(d,:))
            end
            xlabel(sprintf('Peak %d', x_axis))
            ylabel(sprintf('Peak %d', y_axis))
            title(sprintf('Cluster %d (%d) [%.3f, %.3f, %.3f %.3f]', c, ...
                length(the_cluster_filters{c}), the_gradings(c, 1), ...
                the_gradings(c, 2), the_gradings(c, 3), the_gradings(c, 4)))
            title(sprintf('Cluster %d (%d)', c, length(the_cluster_filters{c})))
            hold off
        	set(gcf, 'Visible', 'on')
            set(gcf, 'InvertHardCopy', 'off')
        end
    else
        mean_ratings = mean(ratings, 2);
        [~, inds] = sort(mean_ratings);
        x_axis = inds(1);
        y_axis = inds(2);
        
        figure
        set(gcf, 'Visible', 'off')
        hold on
        
        xlim([0 the_inputrange(x_axis)]);
        ylim([0 the_inputrange(y_axis)]);
        myplot(data(:, x_axis), data(:, y_axis), red)
        for c = 1:length(the_cluster_filters)
            cluster = data(the_cluster_filters{c}, :);
            cluster_x = cluster(:, x_axis);
            cluster_y = cluster(:, y_axis);
            myplot(cluster_x, cluster_y, colors(c,:))
        end
        xlabel(sprintf('Peak %d', x_axis))
        ylabel(sprintf('Peak %d', y_axis))
        title('All clusters')
        hold off
        set(gcf, 'Visible', 'on')
        set(gcf, 'InvertHardCopy', 'off')
    end
    colordef white
end