function [] = get_histogram_to_compare_new_clustering_features(table_with_new_features,normalize_by_probability)

unique_feature_list = unique(table_with_new_features.new_features);
figure;
tiledlayout("flow");
for i=1:length(unique_feature_list)
    nexttile();
    curr_accuracy = table_with_new_features{table_with_new_features.new_features==unique_feature_list(i),"accuracy"};
    if normalize_by_probability
        histogram(curr_accuracy,'BinEdges',1:1:100,'Normalization','probability');
        ylabel("Probability")
        ylim([0,.15]);
        
    else
        histogram(curr_accuracy,'BinEdges',1:1:100);
        ylabel("Counts")
        ylim([0,10]);
    end
    just_the_table = table_with_new_features(table_with_new_features.new_features==unique_feature_list(i) & table_with_new_features.accuracy>80,:);
    xlabel("accuracy")
    title_string = strrep(unique_feature_list(i),"_"," ")+...
        "\n found "+string(length(curr_accuracy))+" clusters"+ ...
    "\n found "+string(length(curr_accuracy(curr_accuracy>80)))+" clusters > 80 accurate"+...
    "\n found " + string(length(unique(just_the_table.Max_Overlap_Unit)))+" unique units >80";
    text(0.5, 0.98, sprintf(title_string), ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', ...
    'FontWeight', 'bold');
    xlim([80,100])
end

end