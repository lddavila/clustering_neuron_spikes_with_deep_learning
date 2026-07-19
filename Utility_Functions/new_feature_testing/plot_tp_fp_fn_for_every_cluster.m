function [] = plot_tp_fp_fn_for_every_cluster(blind_pass_table,config,normalize_or_dont)

dir_to_save_plots_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"tp_fp_fn_bars"));

unique_units = unique(blind_pass_table.Max_Overlap_Unit);
array_of_data = zeros(length(unique_units),3);

for i=1:length(unique_units)
    current_reps = blind_pass_table(blind_pass_table{:,"Max_Overlap_Unit"}==unique_units(i),:);

    [~,max_idx] = max(current_reps.accuracy);
    if normalize_or_dont
        the_denom = sum(current_reps{max_idx,["tp","fn","fp"]});
        array_of_data(i,1) = current_reps{max_idx,"tp"} / the_denom;
        array_of_data(i,2) = current_reps{max_idx,"fn"} / the_denom;
        array_of_data(i,3) = current_reps{max_idx,"fp"} / the_denom;
    else
        array_of_data(i,1) = current_reps{max_idx,"tp"};
        array_of_data(i,2) = current_reps{max_idx,"fn"};
        array_of_data(i,3) = current_reps{max_idx,"fp"};
    end
end
x_labels = strcat("unit\_"+string(unique_units));
f = figure('units','normalized','outerposition',[0 0 1 1]);
bar(x_labels,array_of_data,'stacked')
if normalize_or_dont
    save_plots_in_all_formats(f,fullfile(dir_to_save_plots_to,"tp_fp_fn_rate_bar_plot_normalized"))
else
    save_plots_in_all_formats(f,fullfile(dir_to_save_plots_to,"tp_fp_fn_rate_bar_plot"))

end
legend("True Positive","False Negative","False Positive")
end