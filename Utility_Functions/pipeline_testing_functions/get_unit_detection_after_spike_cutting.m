function [] = get_unit_detection_after_spike_cutting(config,lowest_bound_spike_windows_dir,ground_truth)
%this function serves to see if we lose any spikes when cutting the spike
%windows
%while theoretically possible the loss should be so miniscule as to be less
%then .1% in most cases if not 0. If a high amount of loss occurs then
%something in unhealthy in the pipeline

finished_status_save_name = fullfile(config.dir_to_save_debug_files_to,"finished_after_spike_cutting_detection.txt");

if ~isfile(finished_status_save_name)

    %import the table of best rep
    table_of_best_rep = importdata(config.fp_to_table_of_best_rep);
    spike_windows_table = struct2table(dir(fullfile(lowest_bound_spike_windows_dir,"*.mat")));
    spike_windows_table.folder = string(spike_windows_table.folder);
    spike_windows_table.name = string(spike_windows_table.name);
    spike_windows_cell_array = cell(height(spike_windows_table),1);
    stage_2_detection_levels = zeros(height(table_of_best_rep),1);

    % import the spike windows data
    parfor i=1:height(spike_windows_table)
        % disp(i);
        spike_windows_cell_array{i} = importdata(fullfile(spike_windows_table{i,"folder"},"c"+string(i)+".mat"));
    end

    number_of_iterations = height(table_of_best_rep);
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    print_status_bar(number_of_iterations,"get_unit_detection_after_spike_cutting.m")
    parfor i=1:height(table_of_best_rep)
        current_spike_windows = spike_windows_cell_array{table_of_best_rep{i,"all_channels"}};
        % if size(current_spike_windows,1) ~= length(cell_array_of_all_spikes_per_channel{i})
        %     disp("data loss occured")
        % end

        %get the ground truth we'll use for this
        gt_unit_to_use_for_this = table_of_best_rep{i,"unit"};
        filter_to_use = table_of_best_rep{i,"mult_in_mv"};
        filtered_spike_windows = double(current_spike_windows(abs(current_spike_windows(:,5)) >= filter_to_use,:));

        try
            current_ground_truth_idxs = ground_truth{gt_unit_to_use_for_this};
            %the 6 on line 27 equates to .2 milliseconds of time, %column 4 of spike windows in the original index of the peak detected in previous step
            detection_level_for_current_channel = sum(ismembertol(double(current_ground_truth_idxs),filtered_spike_windows(:,4),6,'DataScale',1))/length(current_ground_truth_idxs) * 100;
            stage_2_detection_levels(i) = detection_level_for_current_channel;
        catch
            send(q,[]);
        end
        send(q,[])
    end
    table_of_best_rep.detection_ratio_after_spike_cutting = stage_2_detection_levels;
    par_save(config.fp_to_table_of_best_rep,table_of_best_rep)

    file_id = fopen(fullfile(finished_status_save_name),"w");
    fclose(file_id);
else
    disp(finished_status_save_name +" already exists, step has been skipped.")
end

end