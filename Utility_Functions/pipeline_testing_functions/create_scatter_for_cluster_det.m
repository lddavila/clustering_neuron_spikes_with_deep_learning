function [] = create_scatter_for_cluster_det(percentile_table)



all_prctiles = percentile_table{:,"prctiles_used"};

unique_prctiles = unique(all_prctiles, 'rows', 'stable');
unique_prctiles = sortrows(unique_prctiles, [1 2 3 4], "descend");

unique_mults = unique(percentile_table{:,"Multiplier"});

% cluster_size = cellfun("size", percentile_table{:,"timestamps"},1);
% percentile_table.cluster_size = cluster_size;
% [~, uidx] = unique(percentile_table.cluster_size, 'stable');
% percentile_table = percentile_table(uidx, :);

number_of_rows = ceil(sqrt(length(unique_mults)));
number_of_cols = ceil(sqrt(length(unique_mults)));


tiledlayout(number_of_rows,number_of_cols);
for j=1:size(unique_mults)
    labels = strings(size(unique_prctiles,1),1);
    places_to_draw_grid_lines = [];
    current_mult = unique_mults(j);
    all_x = [];
    all_accuracy = [];
    all_cluster_size = [];
    all_increment = [];
    all_cluster_colors = [];
    % nexttile();
    number_of_clusters_to_plot = [];
    for i = 1:size(unique_prctiles,1)

        current_percentiles = unique_prctiles(i,:);
        labels(i) = strjoin(string(current_percentiles), "\_");
        c1 = all(percentile_table{:,"prctiles_used"} == current_percentiles, 2);
        c2 = percentile_table{:,"Multiplier"} ==current_mult;
        rows = percentile_table(c1 & c2, :);

        % cluster_size = cellfun("size", rows{:,"timestamps"},1) ;
        % rows.cluster_size = cluster_size;
        % [~, uidx] = unique(rows.cluster_size, 'stable');
        % rows = rows(uidx, :);

        % cluster_size = cellfun(@numel, rows{:,"timestamps"}) ;
        % max_area = max(cluster_size);
        % current_max_radius = sqrt(max_area / pi);
        % current_max_radius = current_max_radius+1;



        % Change this if your accuracy column has a different name
        accuracy = rows{:,"accuracy"};

        increment = current_percentiles(1) - current_percentiles(2);

        all_x = [all_x; repmat(i, size(rows,1), 1)];
        all_accuracy = [all_accuracy, accuracy.'];
        % all_cluster_size = [all_cluster_size; cluster_size];
        all_increment = [all_increment; repmat(increment, size(rows,1), 1)];
        places_to_draw_grid_lines = [places_to_draw_grid_lines,i+0.5];
        all_cluster_colors = [all_cluster_colors,rows.Multiplier.'];
        number_of_clusters_to_plot = [number_of_clusters_to_plot,string(height(rows))];
    end
    % jitter x-values slightly so overlapping clusters are visible
   % x_jittered = all_x + 0.15 * randn(size(all_x));
    x_jittered = all_x; %actually don't do that cause its hard to read

    figure;
    
    scatter(x_jittered, all_accuracy, repelem(100,length(x_jittered),1),all_cluster_colors, ...
        'filled', 'MarkerFaceAlpha', 0.55)
    hold on;

    text(places_to_draw_grid_lines,repelem(95,1,length(places_to_draw_grid_lines)),number_of_clusters_to_plot);
    xline(places_to_draw_grid_lines)

    xticks(1:numel(labels))
    xticklabels(labels)
    xtickangle(45)

    xlabel("PMV Percentile Window")
    ylabel("Cluster Accuracy")
    title("Cluster Accuracy by PMV Percentile Window "+string(percentile_table{1,"Tetrode"})+" Multiplier "+string(rows{1,"Multiplier"})+" # Clusters: "+string(length(all_accuracy)))

    % cb = colorbar;
    % cb.Label.String = "Multiplier";
    yline(0:10:100)

    title("Multiplier: "+string(current_mult) +" | "+string(length(all_accuracy))+" Clusters found" )


end




end