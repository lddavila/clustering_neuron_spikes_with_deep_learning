function [] = plot_sample_channel_data(blind_pass_table,config,fp_to_thresholds_in_mv,unit_color_map,number_dpts_to_plot)
save_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"sample_channel_data"));

ground_truth = importdata(config.GT_FP);
timestamps = importdata(config.TIMESTAMP_FP);


unique_tetrodes = unique(blind_pass_table{:,"Tetrode"});

thresholds_in_microvolts = importdata(fp_to_thresholds_in_mv);

f = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
tiledlayout(2,1,"Padding","tight");

unique_units = unique(blind_pass_table{:,"Max_Overlap_Unit"});
ground_truth_to_use = ground_truth(unique_units);

%find a section of the channel where all ground truth units are applied 
for i=1:length(unique_tetrodes)
    
    rows_for_current_tetrode = blind_pass_table(blind_pass_table{:,"Tetrode"}==unique_tetrodes(i),:);
    current_channels = rows_for_current_tetrode{i,"channels"};
    current_channels = current_channels([2,4]);
    
    for j=1:length(current_channels)
        nexttile();
        channel_data = importdata(fullfile(config.DIR_WITH_OG_CHANNEL_RECORDINGS, "c"+current_channels(j)+".mat")) ;
        channel_data = channel_data * -1;
        window_beginning = 1;
        window_end = number_dpts_to_plot;
       
      
        plot(channel_data(window_beginning:window_end),'LineWidth',5);
        hold on;
        yline(thresholds_in_microvolts{current_channels(j)},'-','LineWidth',2,'Color','r');
        title("Channel "+string(current_channels(j)))
        
        
    end
end
end