function [] = plot_pmv_tables_scores(pmv_table,scores_to_plot,vars_to_group_by,plot_histograms_too,which_histograms)

sliced_table = slice_table_for_parallel_processing(pmv_table,vars_to_group_by);


for i=1:length(sliced_table)
    % figure;
    current_table = sortrows(sliced_table{i},"percentile","descend");
    f_1 = figure;
    x_data = current_table.percentile;
    y_data = current_table.(scores_to_plot);
    plot(x_data,y_data);
    xlabel("percentile filter (all data not just positive)")
    ylabel(strrep(scores_to_plot,"_","\_"));
    title("Percentile vs ",strrep(scores_to_plot,"_","\_"));
    if plot_histograms_too
        for k=1:height(current_table)
            if which_histograms=="all"
                f_2 = figure();
                tiledlayout('flow');
                all_tab_vars = string(current_table.Properties.VariableNames);
                list_of_all_hist_counts = all_tab_vars(contains(all_tab_vars,"_count"));
                for j=1:length(list_of_all_hist_counts)
                    nexttile();
                    bin_edges = -15:.1:15;
                    histogram('BinEdges',bin_edges,'BinCounts',current_table{k,list_of_all_hist_counts(j)}{1})
                    title(list_of_all_hist_counts(j));
                end
                sgtitle("Percentile "+string(current_table{k,"percentile"}))
                
            end
            close(f_2);
        end
    end

    close(f_1);
end
end