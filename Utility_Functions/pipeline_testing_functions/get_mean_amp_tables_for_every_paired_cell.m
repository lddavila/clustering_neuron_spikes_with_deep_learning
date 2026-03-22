%% set the filepaths
list_of_paired_cell_gt = ["F:\cell_1\ground_truth\ground_truth.mat",...
    "F:\cell_10\ground_truth\ground_truth.mat"...
    "F:\cell_12\ground_truth\ground_truth.mat",...
    "F:\cell_28\ground_truth\ground_truth.mat",...
    "F:\cell_37\ground_truth\ground_truth.mat",...
    "F:\cell_46\ground_truth\ground_truth.mat"];

list_of_directories_with_channel_data = ["F:\cell_1\recordings_by_channel",...
    "F:\cell_10\recordings_by_channel",...
    "F:\cell_12\recordings_by_channel",...
    "F:\cell_28\recordings_by_channel",...
    "F:\cell_37\recordings_by_channel",...
    "F:\cell_46\recordings_by_channel"];

cell_names = ["cell_1","cell_10","cell_12","cell_28","cell_37","cell_46"];

%% get all the recordings by channel but in a filtered format
filtered_directories = repelem("",length(cell_names),1);
ordered_list_of_channels = strcat("c",string(1:384),".mat");
for i=1:length(list_of_directories_with_channel_data)
    current_data_to_filter = list_of_directories_with_channel_data(i);
    filtered_directories(i) = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile("F:",cell_names(i)+"filtered"));
    %apply_filter(ordered_list_of_channels,config,filtered_directories(i),current_data_to_filter)

end
%% get the mean amplitude tables for the filtered data
dir_to_save_filtered_mean_amp_tables_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile("F:","filtered_paired_recording_mean_amp_tables"));
cell_array_of_filtered_paired_tables = cell(length(filtered_directories),1);
for i=1:length(filtered_directories)
    try
        save_name = fullfile(dir_to_save_filtered_mean_amp_tables_to,cell_names(i)+".mat");
        if ~isfile(save_name)
            disp("Working on "+cell_names(i)+" ...")
            current_gt = importdata(list_of_paired_cell_gt(i));
            current_average_amp_table =get_average_amplitude_per_unit_on_each_channel(filtered_directories(i),current_gt,6);
            par_save(save_name,current_average_amp_table);
            cell_array_of_filtered_paired_tables{i} = current_average_amp_table;
        else
            cell_array_of_filtered_paired_tables{i} = importdata(save_name);
        end
    catch ME
        disp("Failed ")
    end
end
% get the mean amplitude tables for the unfiltered data
dir_to_save_mean_amp_tables_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile("F:","unfiltered_paired_recording_mean_amp_tables"));
cell_array_of_paired_tables = cell(length(list_of_directories_with_channel_data),1);
for i=1:length(list_of_paired_cell_gt)
    try
        save_name = fullfile(dir_to_save_mean_amp_tables_to,cell_names(i)+".mat");
        if ~isfile(save_name)
            disp("Working on "+cell_names(i)+" ...")
            current_gt = importdata(list_of_paired_cell_gt(i));
            current_average_amp_table =get_average_amplitude_per_unit_on_each_channel(list_of_directories_with_channel_data(i),current_gt,6);
            par_save(save_name,current_average_amp_table);
            cell_array_of_paired_tables{i} = current_average_amp_table;
        else
            cell_array_of_paired_tables{i} = importdata(save_name);
        end
    catch ME
        disp("Failed")
    end
end

%% plot the ground truth and detected spikes
%both the filtered and unfiltered are not inverted by default
which_channel_to_test = 2;
number_of_dpts_on_either_side = 30;
number_of_gt_idxs_to_plot = 5;
clc;
for i=6:length(cell_array_of_paired_tables)
    %get the best channel for both the filtered and unfiltered data
    filtered_table = cell_array_of_filtered_paired_tables{i};

    above_90_filtered = filtered_table{:,"ratios_for_current_channel"} > 90;
   
    filtered_table(~above_90_filtered,:) = [];
    
    filtered_table = sortrows(filtered_table,"mean_peak_vals","descend");

    unfiltered_table = cell_array_of_paired_tables{i};
    above_90_unfiltered = unfiltered_table{:,"ratios_for_current_channel"} > 80;
    unfiltered_table(~above_90_unfiltered,:) = [];
    unfiltered_table = sortrows(unfiltered_table,"mean_peak_vals","descend");

    current_gt = importdata(list_of_paired_cell_gt(i));

    number_of_plots_you_can_make = ceil(length(current_gt) / number_of_gt_idxs_to_plot);
    starting_point = 1;
    for k=1:number_of_plots_you_can_make
        f = figure;
        tiledlayout(2,number_of_gt_idxs_to_plot);

        first_unfiltered_non_nan = find(~isnan(unfiltered_table.mean_peak_vals),1);
        first_filtered_non_nan = find(~isnan(filtered_table.mean_peak_vals),1);


        best_unfiltered_channel = unfiltered_table{first_unfiltered_non_nan,"Var1"};
        best_filtered_channel = filtered_table{first_filtered_non_nan,"Var1"};

        ratio_for_unfiltered_channel = unfiltered_table{first_unfiltered_non_nan,"ratios_for_current_channel"};
        ratio_for_filtered_channel = filtered_table{first_filtered_non_nan,"ratios_for_current_channel"};

        y_data_unfiltered = importdata(fullfile(list_of_directories_with_channel_data(i),best_unfiltered_channel));
        y_data_filtered = importdata(fullfile(filtered_directories(i),best_filtered_channel));
        y_data_filtered = y_data_filtered*-1;

        equivalent_in_unfiltered = unfiltered_table{first_unfiltered_non_nan,"equivalent_peaks"}{1};
        equivalent_in_filtered = filtered_table{first_filtered_non_nan,"equivalent_peaks"}{1};
        for j=starting_point:starting_point+number_of_gt_idxs_to_plot-1
            nexttile();
            window_start = current_gt(j)-number_of_dpts_on_either_side;
            window_end = current_gt(j)+number_of_dpts_on_either_side;
            subset_x_data = window_start:window_end;
            subset_y_data_unfiltered = y_data_unfiltered(window_start:window_end) ;
            plot(subset_x_data,subset_y_data_unfiltered)
            hold on;
            scatter(current_gt(j),y_data_unfiltered(current_gt(j)),60,'red','filled');
            if ~isnan(equivalent_in_unfiltered(j)) && equivalent_in_unfiltered(j) ~=0
                scatter(equivalent_in_unfiltered(j),y_data_unfiltered(equivalent_in_unfiltered(j)),'black','filled')
            end
            if mod(j,number_of_gt_idxs_to_plot)==1
                ylabel("Unfiltered")
                title(best_unfiltered_channel);
                subtitle("Red is gt black is detected equivalent spike")
            end
        end

        for j=starting_point:starting_point+number_of_gt_idxs_to_plot-1
            nexttile();
            window_start = current_gt(j)-number_of_dpts_on_either_side;
            window_end = current_gt(j)+number_of_dpts_on_either_side;
            subset_x_data = window_start:window_end;
            subset_y_data_filtered = y_data_filtered(window_start:window_end);
            plot(subset_x_data,subset_y_data_filtered)
            hold on;
            scatter(current_gt(j),y_data_filtered(current_gt(j)),60,'red','filled');
            if ~isnan(equivalent_in_filtered(j)) && equivalent_in_filtered(j) ~= 0
                scatter(equivalent_in_filtered(j),y_data_filtered(equivalent_in_filtered(j)),'black','filled')
            end
            if mod(j,number_of_gt_idxs_to_plot)==1
                ylabel("Filtered")
                title(best_unfiltered_channel);
            end
            starting_point = starting_point+1;
        end
        sgtitle(cell_names(i) +" Unfiltered coverage is: "+string(ratio_for_unfiltered_channel)+" filtered coverage is "+string(ratio_for_filtered_channel))
        try
            close(f);
        catch
        end
    end




end

