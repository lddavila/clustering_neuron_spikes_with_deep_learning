function [] = examine_percentile_tables(percentile_table)
multiplier = percentile_table{1,"Multiplier"};
all_prctiles = percentile_table{:,"prctiles_used"};
all_increments = unique(all_prctiles(:,1) - all_prctiles(:,2));

%what are the metrics that i care about?
%how many clusters did I find
%what accuracy are those clusters found
%what window is being used?
unique_prctiles = unique(all_prctiles,'rows','stable');
unique_prctiles = sortrows(unique_prctiles,[1,2,3,4],"descend");

f = figure;
x_data = 100:-5:1;
% y_data = repelem(1,1,length(x_data));
% plot(x_data, y_data, '-o')

y_loc = 2;
for i=1:size(unique_prctiles,1)
    current_percentiles =unique_prctiles(i,:) ;
    x_data = strjoin(string(current_percentiles),"\_");
    bin_start = current_percentiles(1);
    bin_end = current_percentiles(end);
    only_rows_of_current_prctile = percentile_table(all(percentile_table{:,"prctiles_used"}==current_percentiles,2),:);
    cluster_size = cellfun("size", only_rows_of_current_prctile{:,"timestamps"},1);
    only_rows_of_current_prctile.cluster_size = cluster_size;
    [~, uidx] = unique(only_rows_of_current_prctile.cluster_size, 'stable');
    T_unique = only_rows_of_current_prctile(uidx, :);
    bar(x_data,size(T_unique,1))
    hold on;
    % plot(x_data, y_data, '-o')
    y_loc = y_loc +1;
end
xlabel("Percentiles of pmv")
ylabel("# of clusters found")
end