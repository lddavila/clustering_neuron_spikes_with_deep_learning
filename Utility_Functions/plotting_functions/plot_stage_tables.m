function [] = plot_stage_tables(stage_table,z_score_or_multiplier,config,the_input_dir,varargin)
dir_to_save_plots_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"snr and det plots"));
dir_to_save_plots_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,the_input_dir  ));
colors_for_plot = distinguishable_colors(max([length(config.DEFAULT_CLUSTERING_Z_SCORES),length(config.Multipliers)]));
% all_table_names = string(stage_table.Properties.VariableNames);
if isempty(varargin)
    if z_score_or_multiplier == "z score"
        stage_table.("z score") = stage_table.all_multiplier_idxs;
        append_names = ["unit","tetrode","z score"];
    else
        append_names = ["unit","tetrode","all_multiplier_idxs"];
    end

    save_grouped_save_name = fullfile(dir_to_save_plots_to,"grouped_table.mat");
    if isfile(save_grouped_save_name)
        grouped_table = importdata(save_grouped_save_name);
    else
        grouped_table = slice_table_for_parallel_processing(stage_table,["tetrode","unit"]);
        par_save(save_grouped_save_name,grouped_table);
    end
else
    grouped_table = varargin{1};
end
for i=1:length(grouped_table)
    current_table = grouped_table{i};


    f =figure('units','normalized','outerposition',[0 0 1 1]);
    tiledlayout('flow');
    for k=1:2
        nexttile();

        for j=1:height(current_table)
            local_data = current_table(j,:);
            columns_with_nan = varfun(@(x) any(ismissing(x)), local_data, ...
                "OutputFormat","uniform");

            local_data(:, columns_with_nan) = [];
            all_table_names = string(local_data.Properties.VariableNames);

            detection_ratio_all_names = all_table_names(startsWith(all_table_names,"detection_ratio_stage_")).';
            snr_all_names = all_table_names(startsWith(all_table_names,"raw_snr_stage_")).';

            detect_rat_subset = detection_ratio_all_names(contains(detection_ratio_all_names,"prc"));
            snr_subset = snr_all_names(contains(snr_all_names,"prc"));

            snr_names_before_prc =setdiff(snr_all_names,snr_subset);
            split_snr_names_before_prc = split(snr_names_before_prc,"_");
            dr_names_before_prc = setdiff(detection_ratio_all_names,detect_rat_subset);
            split_dr_names_before_prc = split(dr_names_before_prc,"_");

            

            split_dr_subset = split(detect_rat_subset,"_");
            the_unique_col_start = find(split_dr_subset(1,:)=="stage")+1; %everything after this column is unique
            unique_dr_ends = unique(join(split_dr_subset(:,the_unique_col_start:end),"_"));

            split_snr_subset = split(snr_subset,"_");
            the_unique_col_start = find(split_snr_subset(1,:)=="stage")+1; %everything after this column is unique
            unique_snr_ends = unique(join(split_snr_subset(:,the_unique_col_start:end),"_"));


            dratio_stage = [str2double(strrep(split_dr_subset(:,4),"prc",""));str2double(split_dr_names_before_prc(:,end))];
            dr_names = [detect_rat_subset;dr_names_before_prc];

            snr_stage = [str2double(strrep(split_snr_subset(:,4),"prc",""));str2double(split_snr_names_before_prc(:,end))];
            snr_names = [snr_subset;snr_names_before_prc];

            name_table = table(dr_names,snr_names,dratio_stage,snr_stage);
            name_table = sortrows(name_table,"snr_stage");

            %they should have the exact same number of stages so just
            %ensure that we the stage numbers are identical
            if any(name_table{:,"dratio_stage"} ~= name_table{:,"snr_stage"})
                disp("Something went wrong");
                continue;
            end

            
            % detection_ratio_names = strcat("detection_ratio_stageprc_",string(1:length(detection_names)));
            if k==1
                which_names = name_table{:,"dr_names"};
                show_name = "detection ratio z score "+string(current_table{j,"z score"});
            else
                which_names = name_table{:,"snr_names"};
                show_name = "snr perc z score "+string(current_table{j,"z score"});
            end
            y_data_1 = current_table{j,which_names};
            % y_data_2 = current_table{j,idx_snr_names};
            has_prc = contains(which_names,"prc");

            x_data = [strcat("filter_",string(1:(length(which_names)-sum(has_prc)))),strcat("prc_",string(99:-1:1))];
            x_tics = 1:length(y_data_1);
            if z_score_or_multiplier == "z score"
                plot(x_tics,y_data_1,'DisplayName',show_name,'Color',colors_for_plot(j,:),'LineWidth',2);
                xticks(x_tics);
                xticklabels(x_data);
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