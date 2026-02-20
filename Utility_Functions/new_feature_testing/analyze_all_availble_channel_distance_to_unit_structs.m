function [] = analyze_all_availble_channel_distance_to_unit_structs(fp_to_check,dir_to_save_plots_to,closest_n_neurons,distance_bins)
list_of_all_files = struct2table(dir(fullfile(fp_to_check, '**', '*.mat')));

%filter out the rows that aren't in a channel_distances_to_units directory
list_of_all_files = list_of_all_files(contains(string(list_of_all_files{:,"folder"}),"channel_distances_to_units"),:);

%import all the available data
if ~isfile(fullfile(dir_to_save_plots_to,"full_struct.mat"))
    data_cell_array = cell(size(list_of_all_files,1),8);
    for i=1:height(list_of_all_files)
        data_fp = fullfile(string(list_of_all_files{i,"folder"}),string(list_of_all_files{i,"name"}));
        split_fp = split(data_fp,filesep,2);
        data_cell_array{i,1} = importdata(data_fp);
        data_cell_array{i,2} = data_cell_array{i,1}.table_of_distance;
        data_cell_array{i,3} = data_cell_array{i,1}.ironclust_ratios;
        data_cell_array{i,4} = data_cell_array{i,1}.ironclust_noise_ratio;
        data_cell_array{i,5} = data_cell_array{i,1}.ironclust_thresholds.';
        data_cell_array{i,6} = split_fp(2);
        data_cell_array{i,7} = split_fp(3);
        data_cell_array{i,8} = string(list_of_all_files{i,"name"});
        fprintf("%i/%i\n",i,height(list_of_all_files));

    end
    par_save(fullfile(dir_to_save_plots_to,"full_struct.mat"),data_cell_array)
else
    data_cell_array = importdata(fullfile(dir_to_save_plots_to,"full_struct.mat"));
end
%now we can take the nth closest_n_neurons from each channel and create plots
%which will show how the noise/signal ratio if affected on average
data_table = cell2table(data_cell_array);
unique_recording_names = unique(string(data_cell_array(:,6)));

some_thing = [];

for i=1:length(unique_recording_names)
    figure;
    current_data = data_cell_array(data_table{:,"data_cell_array6"}==unique_recording_names(i),:);
    distance_of_closest_n = cellfun(@(x) x{1:closest_n_neurons,"Distance"}, current_data(:,2));
    [min_dist,max_dist] = bounds(distance_of_closest_n);

    some_thing = [some_thing;min_dist,max_dist];

    noise_ratio_of_closest_n = cell2mat(cellfun(@(x) x(1:closest_n_neurons,:),current_data(:,3),"UniformOutput",false));
    signal_ratio_of_closest_n = cell2mat(cellfun(@(x) x(1:closest_n_neurons,:),current_data(:,4),"UniformOutput",false));
    filter_values = cell2mat(current_data(:,5));
    average_filter_values = mean(filter_values,1);

    tiledlayout(2,3)
    cell_array_of_vals = cell(length(distance_bins)-1,1);
    for j=1:length(distance_bins)-1
        nexttile;
        % yyaxis left
        try
            plot(average_filter_values,signal_ratio_of_closest_n(distance_of_closest_n>=distance_bins(j) & distance_of_closest_n < distance_bins(j+1),:))
        catch
        end
        ylabel("Signal Ratio")
        % ylim([0,1])

        % yyaxis right
        % nexttile
        % plot(average_filter_values,noise_ratio_of_closest_n)
        % ylabel("Noise Ratio")
        % ylim([0,1])

        %find where the average signal ratio drops below .9 and plot a yline
        %there
        hold on;
        threshs_found = .9:-.1:0;
        vals = nan(length(.9:-.1:0),1);
        for k=1:length(threshs_found)
            loc = find(mean(signal_ratio_of_closest_n(distance_of_closest_n>distance_bins(j) & distance_of_closest_n < distance_bins(j+1),:),1) < threshs_found(k),1);
            if isempty(loc)
                continue;
            end
            vals(k) = average_filter_values(loc);
            xline(average_filter_values(loc),"LineWidth",2,"Color",'k','Label',"Avg Coverage Drops below:"+string(threshs_found(k))+" || "+sprintf("%.2f",average_filter_values(loc)),'LabelHorizontalAlignment','left');
        end
        cell_array_of_vals{j} = vals.';
        title("From "+string(distance_bins(j))+" To "+string(distance_bins(j+1)))
        
        try
            xlim([min(vals)-15,max(vals)+15])
        catch
        end
        
    end
    avg_thresholds = mean(cell2mat(cell_array_of_vals),1,"omitnan");
    disp(avg_thresholds);
    sgtitle(unique_recording_names(i));
    
    
end
% sgtitle("Closest "+string(closest_n_neurons)+" Ranging from "+string(min_dist) +" to "+string(max_dist) )
% xlabel("Threshold in microvolts")
% legend(unique_recording_names(1)+" Ranging from "+string(some_thing(1,1)) +" to "+string(some_thing(1,2)),...
%     unique_recording_names(3)+" Ranging from "+string(some_thing(2,1)) +" to "+string(some_thing(2,2)),...
%     unique_recording_names(3)+" Ranging from "+string(some_thing(3,1)) +" to "+string(some_thing(3,2)))
end