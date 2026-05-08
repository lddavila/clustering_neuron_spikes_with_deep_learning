function [config] = check_unit_detection_while_clustering(filtered_spike_windows,current_tetrode,config,stage,varargin)

%depending on which stage of clustering we're at we may have the aligned data, and if we do then we can create a plot
%where the peaks of all the spikes are created and and we color code those spikes per unit
debug_plot_dir =create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.dir_to_save_debug_files_to,"plots"));
current_tetrode_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(debug_plot_dir,config.tetrode));
current_prc_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(current_tetrode_dir,strjoin(string(config.percentiles_to_use),"_")));
current_mult_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(current_prc_dir,"Mult_"+string(config.which_thresh)));

save_dir = fullfile(config.dir_to_save_debug_files_to,stage+strjoin(string(config.percentiles_to_use),"_"));
save_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(save_dir);
table_save_name = fullfile(save_dir,current_tetrode+"_mult_"+string(config.which_thresh)+".mat");
fig_save_name = fullfile(current_mult_dir,"stage_"+config.plot_counter+current_tetrode+"mult"+string(config.which_thresh));

table_of_best_rep = importdata(config.fp_to_table_of_best_rep);

colors_dict = containers.Map('KeyType','char','ValueType','any');
list_of_gt_units = 1:length(config.ground_truth_cell_array);
unit_colors = distinguishable_colors(length(list_of_gt_units));
for i=1:length(list_of_gt_units)
    colors_dict(string(i)) = unit_colors(i,:);
end

%filter down to only the tetrodes which match the current tetrode which
%threshold is currently being used by the clustering algorithm
current_tetrode_cond = table_of_best_rep{:,"tetrode"}==current_tetrode;
current_thresh_cond = table_of_best_rep{:,"all_multiplier_idxs"}==config.which_thresh;
filtered_table_of_best_rep = table_of_best_rep(current_thresh_cond & current_tetrode_cond,:);
if ~isempty(filtered_spike_windows)
    %now for all the units at this level determine the signal detection ratio
    peak_locs = filtered_spike_windows(:,4);
    det_rat_of_current_stage = zeros(height(filtered_table_of_best_rep),1);
    loc_of_plots_per_unit = cell(height(filtered_table_of_best_rep),1);
    tol_amount = 6; %equates to approximately .2 milliseconds

    for i=1:height(filtered_table_of_best_rep)
        current_ground_truth_idxs = config.ground_truth_cell_array{filtered_table_of_best_rep{i,"unit"}};
        [is_member_tol_result,loc_of_plots_per_unit{i}] = ismembertol(double(round(current_ground_truth_idxs)), double(round(peak_locs)),tol_amount,'DataScale',1);
        det_rat_of_current_stage(i)= (sum(is_member_tol_result) / length(current_ground_truth_idxs))*100;
    end
    filtered_table_of_best_rep.(stage) = det_rat_of_current_stage;

else
    filtered_table_of_best_rep.(stage) = zeros(height(filtered_table_of_best_rep),1);
end

try
    par_save(table_save_name,filtered_table_of_best_rep);
catch
end
% else
%     filtered_table_of_best_rep = importdata(file_save_name);
% end
if ~isfile(fig_save_name+".png")
    if ~isempty(varargin)
        filter = varargin{2};
        aligned = varargin{1};
        aligned = aligned(:,filter,:);
        peaks = get_peaks(aligned,true);
        % tetrode_number = str2double(strrep(current_tetrode,"t",""));
        % tetrode_channels = config.ART_TETR_ARRAY(tetrode_number,:);
        all_plot_combinations = nchoosek(1:4,2);

        f = figure('Units', 'normalized', 'OuterPosition', [0 0 1 1],'Visible','off');
        tiledlayout(floor(sqrt(size(all_plot_combinations,1))),ceil(sqrt(size(all_plot_combinations,1))))
        for i=1:size(all_plot_combinations,1)
            nexttile();
            x_data = peaks(all_plot_combinations(i,1),:).';
            y_data = peaks(all_plot_combinations(i,2),:).';
            scatter(x_data,y_data,1,[.7 .7 .7],'filled');
            hold on;
            for j=1:height(filtered_table_of_best_rep)
                loc_to_use = loc_of_plots_per_unit{j};
                max_overlap_unit = filtered_table_of_best_rep{j,"unit"};
                loc_to_use(loc_to_use==0) = [];
                current_unit_x = x_data(loc_to_use);
                current_unit_y = y_data(loc_to_use);
                scatter(current_unit_x,current_unit_y,3,colors_dict(string(max_overlap_unit)),'filled');
            end

        end

        sgtitle(strrep(stage,"_","\_"))
        try
            save_plots_in_all_formats(f,strrep(fig_save_name,".mat",""));
        catch
        end
        close(f);
    end
end
config.fp_to_table_of_best_rep = table_save_name;
end