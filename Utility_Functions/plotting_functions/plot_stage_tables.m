function [] = plot_stage_tables(stage_table,z_score_or_multiplier,config)
dir_to_save_plots_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"snr and det plots"));

all_table_names = string(stage_table.Properties.VariableNames);
if z_score_or_multiplier == "z score"
    stage_table.("z score") = stage_table.all_multiplier_idxs;
    append_names = ["unit","tetrode","z score"];
else
    append_names = ["unit","tetrode","all_multiplier_idxs"];
end

grouped_table = slice_table_for_parallel_processing(stage_table,["tetrode","unit"]);

for i=1:length(grouped_table)
    current_table = grouped_table{i};
    raw_snr_names = all_table_names(contains(all_table_names,"raw_snr_stage_"));
    idx_snr_names = strcat("raw_snr_stage_",string(1:length(raw_snr_names)));
    detection_names = all_table_names(contains(all_table_names,"detection_ratio_stage_"));
    detection_ratio_names = strcat("detection_ratio_stage_",string(1:length(detection_names)));
    disp("Signal to noise ratio at every stage");
    disp(current_table(:,[append_names,idx_snr_names]));
    disp("Ratio of unit spikes detected at every stage");
    disp(current_table(:,[append_names,detection_ratio_names]));
    x_data = 1:length(raw_snr_names);
    f =figure;
    tiledlayout('flow');
    for k=1:2
        nexttile();

        for j=1:height(current_table)
            if k==1
                which_names = detection_ratio_names;
                show_name = "detection ratio z score "+string(current_table{j,"z score"});
            else
                which_names = idx_snr_names;
                show_name = "snr perc z score "+string(current_table{j,"z score"});
            end
            y_data_1 = current_table{j,which_names};
            % y_data_2 = current_table{j,idx_snr_names};
            if z_score_or_multiplier == "z score"
                plot(x_data,y_data_1,'DisplayName',show_name);
                hold on;

            end
        end

        if k==1
            xlabel("Stage")
            ylabel("Detection ratio")
            title("Detection Ratio")
        else
            xlabel("Stage")
            ylabel("SNR ratio")
            title("Signal to noise ratio")
        end
        
        legend;
    end
    
    sgtitle("Unit "+string(current_table{1,"unit"}))
    save_name = fullfile(dir_to_save_plots_to,string(current_table{1,"unit"})+" "+string(current_table{1,"tetrode"}));
    save_plots_in_all_formats(f,save_name);
    close(f);

end
end