function [] = general_peak_plotting_function(data_to_plot,config,options)
arguments
    data_to_plot ;
    config struct;
    options.save_plots logical = false;
    options.optional_alternate_grade_path string = "";
    options.where_to_save string = ""
    options.save_name string = ""
    options.what_kind_of_data string = "";
    options.cluster_idx cell = {};
    options.channels cell = {[]};
    options.pause_on_each_plot logical = false;
    options.make_new_plot logical = true;
    options.color_by_unit = false;
    options.close_plot = true;
end

    function [f] = plot_peaks(peaks,cluster_idx,save_plots,where_to_save,save_name,pause_on_each_plot,color_by_unit,config,options)
        f = figure('units','normalized','outerposition',[0 0 1 1]);
        perms_of_dimensions = nchoosek(1:min([size(peaks)]),2);
        tiledlayout('flow');
        cluster_colors = distinguishable_colors(length(cluster_idx));
        legend_string = repelem("",length(cluster_idx),1);
        unit_or_cluster = "cluster";
        unit_or_cluster_number = 1:1:length(cluster_idx);
        if ~isempty(options.channels{1})
            current_channels = options.channels{1};
            perms_of_dimensions = nchoosek(1:length(current_channels),2);
        end
        if color_by_unit
            [cluster_idx,cluster_colors,unit_or_cluster_number]= get_peak_idxs_colored_by_unit(config,peaks);
            unit_or_cluster = "unit";

        end

        for k=1:size(perms_of_dimensions,1)
            nexttile;
            scatter(peaks(perms_of_dimensions(k,1),:),peaks(perms_of_dimensions(k,2),:),3,[0.7 0.7 0.7],'filled');
            hold on;

            for j=1:length(cluster_idx)
                current_cluster_idxs = cluster_idx{j};
                scatter(peaks(perms_of_dimensions(k,1),current_cluster_idxs),peaks(perms_of_dimensions(k,2),current_cluster_idxs),3,cluster_colors(j,:),'filled','DisplayName',sprintf("%s %s",unit_or_cluster,unit_or_cluster_number(j)));
                hold on;
            end
            if k==1
                legend();
            end
            if ~isempty(options.channels{1})
                % disp(perms_of_dimensions)
                xlabel("Channel "+string(current_channels(perms_of_dimensions(k,1))) +" (in \muV)")
                ylabel("Channel "+string(current_channels(perms_of_dimensions(k,2))) +" (in \muV)")
            end
        end

        if save_plots
            save_plots_in_all_formats(f,fullfile(where_to_save,save_name));
        end
        if pause_on_each_plot
            disp("Hit any key to go to next plot")
            pause;
        end
        if options.close_plot
            close(f)
        end
    end


if ~isfolder(options.where_to_save) && options.where_to_save ~= ""
    where_to_save = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,where_to_save));
end

if options.what_kind_of_data=="blind_pass_table"
    %split the blind pass table by its aligned files
    split_table = slice_table_for_parallel_processing(data_to_plot,"fp_to_aligned");
    for i=1:length(split_table)
        current_data = split_table{i};
        aligned = load(current_data{1,"fp_to_aligned"});
        aligned = aligned.data_to_save;
        peaks = get_peaks(aligned,true);
        plot_peaks(peaks,current_data.cluster_idx,options.save_plots,options.where_to_save,options.save_name,options.pause_on_each_plot,options.color_by_unit,config,options);
    end
elseif options.what_kind_of_data=="peaks"
    plot_peaks(data_to_plot,options.cluster_idx,options.save_plots,options.where_to_save,options.save_name,options.pause_on_each_plot,options.color_by_unit,config,options);
elseif options.what_kind_of_data == "aligned"
    peaks = get_peaks(data_to_plot,true);
    plot_peaks(peaks,where_to_save,save_name);
end


end