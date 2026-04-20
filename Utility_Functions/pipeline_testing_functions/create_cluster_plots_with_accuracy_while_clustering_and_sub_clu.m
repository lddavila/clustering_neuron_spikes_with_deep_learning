function create_cluster_plots_with_accuracy_while_clustering_and_sub_clu(config,aligned,cluster_idx_struct,which_clustering_level,varargin)


%get a dictionary that assigns a unique color for each unit
colors_dict = containers.Map('KeyType','char','ValueType','any');
list_of_gt_units = 1:length(config.ground_truth_cell_array);
unit_colors = distinguishable_colors(length(list_of_gt_units));
for i=1:length(list_of_gt_units)
    colors_dict(string(i)) = unit_colors(i,:);
end

%get the peaks of the aligned
peaks = get_peaks(aligned,true);

%get table of best rep
best_rep_local = config.current_table_of_best_rep;
unique_gt_units = unique(best_rep_local.unit);

%get the spike windows we'll use for this
if isempty(varargin)
    spike_windows_to_use = config.secondary_spike_windows;
else
    spike_windows_to_use = config.mutated_spike_windows;
end
%filter based on true spike idx
% spike_windows_to_use = spike_windows_to_use(config.true_spike_idx,:);

%now plot and calculate for each cluster which unit it best represents
f = figure('Units', 'normalized', 'OuterPosition', [0 0 1 1],'Visible','off');
tiledlayout(2,3)
all_dim_combos = nchoosek(1:4,2);

legend_string = ["unclustered"];
for i=1:size(all_dim_combos,1)
    nexttile();
    x_unclustered = peaks(all_dim_combos(i,1),:);
    y_unclustered = peaks(all_dim_combos(i,2),:);
    scatter(x_unclustered,y_unclustered,3,[.7 .7 .7]);
    hold on;

    for j=1:length(cluster_idx_struct)
        if ~isempty(varargin)
            current_idx = cluster_idx_struct{j};
        else
            current_idx = cluster_idx_struct{j}.idx;
        end
        peak_locs = spike_windows_to_use(current_idx,4);
        tol_amount = 6; %equates to approximately .2 milliseconds
        cluster_x = x_unclustered(current_idx);
        cluster_y = y_unclustered(current_idx);
        the_bound_line = boundary(double(cluster_x.'),double(cluster_y.'),1);
        all_overlaps = zeros(length(unique_gt_units),1);
        all_locations = cell(length(unique_gt_units),1);
        for k=1:length(unique_gt_units)
            current_ground_truth_idxs = config.ground_truth_cell_array{unique_gt_units(k)};
            % current_ground_truth_idxs = config.ground_truth_cell_array{filtered_table_of_best_rep{i,"unit"}};
            [is_member_tol_result,all_locations{k}] = ismembertol(double(round(current_ground_truth_idxs)), double(round(peak_locs)),tol_amount,'DataScale',1);
            all_overlaps(k)= (sum(is_member_tol_result) / length(current_ground_truth_idxs))*100;
        end
        % [max_overlap,loc_of_max_unit] = max(all_overlaps);
        % max_overlap_unit = unique_gt_units(loc_of_max_unit);
        % cluster_color = colors_dict(string(max_overlap_unit));
        % scatter(cluster_x,cluster_y,5,cluster_color)
        plot(cluster_x(the_bound_line),cluster_y(the_bound_line),'LineWidth',4);

        if i==1
            legend_string = [legend_string,"Cluster "+string(j)];
    
        end
        for k=1:length(unique_gt_units)
            current_unit = unique_gt_units(k);
            all_local_locations = all_locations{k};
            all_local_locations(all_local_locations ==0) = [];
            unit_x = cluster_x(all_local_locations);
            unit_y = cluster_y(all_local_locations);
            unit_color = colors_dict(string(current_unit));
            scatter(unit_x,unit_y,5,unit_color,"filled");
            if i==1 && j==1
                local_name =  "unit: " +string(unique_gt_units(k))+ " detection ratio: " + string(all_overlaps(k));
                legend_string =[legend_string,local_name];
            end
        end
        % 
    end
end
legend(legend_string);
if ~isempty(varargin)
    save_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.dir_to_save_debug_files_to,"plotting_clustering_refinement_stages"));
    save_name = config.tetrode+" Clustering Level "+string(which_clustering_level)+" subset "+string(config.which_subset)+varargin{1};
else
    save_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.dir_to_save_debug_files_to,"plotting_clustering_stages"));
    save_name = config.tetrode+" Clustering Level "+string(which_clustering_level)+" subset "+string(config.which_subset);
end

sgtitle(save_name);
save_plots_in_all_formats(f,fullfile(save_dir,save_name))
close(f);
end