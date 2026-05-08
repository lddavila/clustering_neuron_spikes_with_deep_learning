function [] = create_scatter(percentile_table)

all_x = [];
all_accuracy = [];
all_cluster_size = [];
all_increment = [];

all_prctiles = percentile_table{:,"prctiles_used"};

unique_prctiles = unique(all_prctiles, 'rows', 'stable');
unique_prctiles = sortrows(unique_prctiles, [1 2 3 4], "descend");

cluster_size = cellfun("size", percentile_table{:,"timestamps"},1);
percentile_table.cluster_size = cluster_size;
[~, uidx] = unique(percentile_table.cluster_size, 'stable');
percentile_table = percentile_table(uidx, :);

labels = strings(size(unique_prctiles,1),1);
places_to_draw_grid_lines = [];
x_loc = 1;
number_of_dots = 0;
max_radius = 1;
for i = 1:size(unique_prctiles,1)

    current_percentiles = unique_prctiles(i,:);
    labels(i) = strjoin(string(current_percentiles), "\_");

    rows = percentile_table( ...
        all(percentile_table{:,"prctiles_used"} == current_percentiles, 2), :);

    cluster_size = cellfun("size", rows{:,"timestamps"},1) ;
    rows.cluster_size = cluster_size;
    [~, uidx] = unique(rows.cluster_size, 'stable');
    rows = rows(uidx, :);

    cluster_size = cellfun(@numel, rows{:,"timestamps"}) ;
    max_area = max(cluster_size);
    current_max_radius = sqrt(max_area / pi);
    current_max_radius = current_max_radius+1;

    

    % Change this if your accuracy column has a different name
    accuracy = rows{:,"accuracy"};

    increment = current_percentiles(1) - current_percentiles(2);

    all_x = [all_x; repmat(i, numel(cluster_size), 1)];
    all_accuracy = [all_accuracy; accuracy];
    all_cluster_size = [all_cluster_size; cluster_size];
    all_increment = [all_increment; repmat(increment, numel(cluster_size), 1)];
    places_to_draw_grid_lines = [places_to_draw_grid_lines,i+0.5];
    % number_of_dots
end

% jitter x-values slightly so overlapping clusters are visible
x_jittered = all_x + 0.15 * randn(size(all_x));
x_jittered = all_x;

figure
scatter(x_jittered, all_accuracy, repelem(100,length(x_jittered),1),all_cluster_size, ...
    'filled', 'MarkerFaceAlpha', 0.55)
hold on;
xline(places_to_draw_grid_lines)

xticks(1:numel(labels))
xticklabels(labels)
xtickangle(45)

xlabel("PMV Percentile Window")
ylabel("Cluster Accuracy")
title("Cluster Accuracy by PMV Percentile Window "+string(percentile_table{1,"Tetrode"})+" Multiplier "+string(percentile_table{1,"Multiplier"})+" # Clusters: "+string(size(percentile_table,1)))

cb = colorbar;
cb.Label.String = "Cluster Size";
yline(0:10:100)

end