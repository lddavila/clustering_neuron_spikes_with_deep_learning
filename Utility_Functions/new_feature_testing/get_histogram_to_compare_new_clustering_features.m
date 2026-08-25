function [] = get_histogram_to_compare_new_clustering_features(table_with_new_features,normalize_by_probability,x_limits,separate_by_num_channels)
if x_limits==0
    x_limits = [0,100];
else
    x_limits = x_limits;
end
unique_feature_list = unique(table_with_new_features.new_features);

all_num_ch = cell2mat(cellfun(@size,table_with_new_features.channels,'UniformOutput',false));
unique_num_ch = unique(all_num_ch(:,2));

all_combos = combinations(unique_num_ch,unique_feature_list);
all_sizes = cell2mat(cellfun(@size, table_with_new_features.channels,'UniformOutput',false));
all_sizes = all_sizes(:,2);
figure;
tiledlayout("flow");
for i=1:size(all_combos,1)
    nexttile();
    c1 = table_with_new_features.new_features==all_combos{i,2};
    c2 = all_sizes==all_combos{i,1};
    if ~separate_by_num_channels
        curr_accuracy = table_with_new_features{ c1,"accuracy"};
    else
        curr_accuracy = table_with_new_features{ c1 & c2,"accuracy"};
    end
    if normalize_by_probability
        histogram(curr_accuracy,'BinEdges',1:1:100,'Normalization','probability');
        ylabel("Probability")
        ylim([0,.15]);
        
    else
        histogram(curr_accuracy,'BinEdges',1:1:100);
        ylabel("Counts")
        ylim([0,10]);
    end
    just_the_table = table_with_new_features(c1 & c2 & table_with_new_features.accuracy>80,:);
    xlabel("accuracy")
    title_string = strrep(all_combos{i,2},"_"," ")+...
        "\n found "+string(length(curr_accuracy))+" clusters"+ ...
    "\n found "+string(length(curr_accuracy(curr_accuracy>80)))+" clusters > 80 accurate"+...
    "\n found " + string(length(unique(just_the_table.Max_Overlap_Unit)))+" unique units >80"+...
    "\n "+string(all_combos{i,1})+" channels";
    text(0.5, 0.98, sprintf(title_string), ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', ...
    'FontWeight', 'bold');
    xlim(x_limits)
end

end