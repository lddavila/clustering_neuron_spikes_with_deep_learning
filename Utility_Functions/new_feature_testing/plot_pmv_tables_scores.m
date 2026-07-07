function [] = plot_pmv_tables_scores(pmv_table,scores_to_plot,vars_to_group_by,plot_histograms_too,which_histograms,dir_to_save_plots_to)

sliced_table = slice_table_for_parallel_processing(pmv_table,vars_to_group_by);

highest_mean_f1_recorded = 0;
z_score_of_highest = 0;
tetrode_of_highest = "";
for i=1:length(sliced_table)
    % figure;
    save_name = fullfile(dir_to_save_plots_to,string(i));
    
    current_table = sortrows(sliced_table{i},"percentile","descend");
    [max_f1,f1_idx] = max(current_table.mean_f1);

    if max_f1 > highest_mean_f1_recorded
        z_score_of_highest = current_table{f1_idx,"z_score"};
        tetrode_of_highest = current_table{f1_idx,"tetrode"};
        highest_mean_f1_recorded = max_f1;
    end
    further_sliced_table = slice_table_for_parallel_processing(current_table,["z_score"]);
    f_1 = figure;
    colors_to_use = distinguishable_colors(length(further_sliced_table));
    for j=1:length(further_sliced_table)
        local_table = sortrows(further_sliced_table{j},"percentile","descend");
        x_data = local_table.percentile;
        y_data = local_table.(scores_to_plot);
        plot(x_data,y_data,'Color',colors_to_use(j,:),'LineWidth',2,'DisplayName'," Z Score "+string(local_table{1,"z_score"}));
        hold on;
    end
    legend();
   
    xlabel("percentile filter (all data not just positive)")
    ylabel(strrep(scores_to_plot,"_","\_"));
    title("Percentile vs "+strrep(scores_to_plot,"_","\_"), current_table{1,"tetrode"}+" Z Score "+string(current_table{1,"z_score"}));
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
    
    save_plots_in_all_formats(f_1,save_name);
    close(f_1);
    
end

fprintf("Highest f_1 was %.2f at %s with z score %i",highest_mean_f1_recorded,tetrode_of_highest,z_score_of_highest);
end