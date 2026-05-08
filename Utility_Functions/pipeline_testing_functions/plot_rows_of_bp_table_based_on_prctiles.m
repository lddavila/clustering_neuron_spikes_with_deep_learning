function [] = plot_rows_of_bp_table_based_on_prctiles(rows,aligned,spike_windows,config,timestamps,ground_truth)
file_to_save_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"plotting_based_on_prctiles"));

unique_prctiles = unique(rows.prctiles_used,'rows','stable');
peaks = get_peaks(aligned,true);



tol_amount = 6;
all_plot_combos = nchoosek(1:size(peaks,1),2);
aligned_ts = timestamps(spike_windows(:,4));

ground_truth = config.ground_truth_cell_array;

colors_dict = containers.Map('KeyType','char','ValueType','any');
list_of_gt_units = 1:length(config.ground_truth_cell_array);
unit_colors = distinguishable_colors(length(list_of_gt_units));
for i=1:length(list_of_gt_units)
    colors_dict(string(i)) = unit_colors(i,:);
end

for i=1:size(unique_prctiles,1)
    only_current_prctiles = rows(all(rows.prctiles_used==unique_prctiles(i,:),2),:);
    if height(only_current_prctiles) >2
        disp("wierd");
    end
    save_name = "prctiles_"+strjoin(string(unique_prctiles(i,:)),"_");
    if ~isfile(save_name+".png")

        f = figure;
        tiledlayout(2,3)

        for j=1:height(all_plot_combos)
            nexttile();
            x_data = peaks(all_plot_combos(j,1),:);
            y_data = peaks(all_plot_combos(j,2),:);

            scatter(x_data,y_data,3,[.7 .7 .7],"filled");
            hold on;
            for k=1:height(only_current_prctiles)
                max_overlap_unit = only_current_prctiles{k,"Max_Overlap_Unit"};
                gt_unit_spike_locs = ground_truth{max_overlap_unit};
                gt_ts = timestamps(gt_unit_spike_locs);

                cluster_ts = only_current_prctiles{k,"timestamps"}{1};
                % accuracy = only_current_prctiles{1,"accuracy"};

                [~,loc_in_aligned] = ismembertol(cluster_ts,aligned_ts,tol_amount,'DataScale',1);
                loc_in_aligned(loc_in_aligned==0) = [];
                cluster_x = x_data(loc_in_aligned);
                cluster_y = y_data(loc_in_aligned);

                the_bound_line = boundary(double(cluster_x.'),double(cluster_y.'),1);

                plot(cluster_x(the_bound_line),cluster_y(the_bound_line),'LineWidth',4);

                [~,unit_loc_in_aligned] = ismembertol(gt_ts,aligned_ts,tol_amount,'DataScale',1);
                unit_loc_in_aligned(unit_loc_in_aligned==0) = [];

                unit_x = x_data(unit_loc_in_aligned);
                unit_y = y_data(unit_loc_in_aligned);
                scatter(unit_x,unit_y,3,colors_dict(string(max_overlap_unit)),'filled')
            end
            % scatter(cluster_x,cluster_y,3,'filled')
        end
        sgtitle(strrep(save_name,"_","\_"));
        save_plots_in_all_formats(f,fullfile(file_to_save_to,save_name));
        close(f);
    end

end
end