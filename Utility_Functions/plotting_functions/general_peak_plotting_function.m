function [] = general_peak_plotting_function(data_to_plot,save_plots,where_to_save,varargin)

    function plot_peaks(peaks,cluster_idx,varargin)
        perms_of_dimensions = nchoosek(1:min([size(peaks)]),2);
        tiledlayout('flow');
        cluster_colors = distinguishable_colors(length(cluster_idx));
        legend_string = repelem("",length(cluster_idx),1);
        if ~isempty(varargin)
            current_channels = varargin{1}{1};
        end

        for k=1:size(perms_of_dimensions,1)
            nexttile;
            scatter(peaks(perms_of_dimensions(k,1),:),peaks(perms_of_dimensions(k,2),:),1,[0.7 0.7 0.7],'filled');
            hold on;
            for j=1:height(cluster_idx)
                current_cluster_idxs = cluster_idx{j};
                scatter(peaks(perms_of_dimensions(k,1),current_cluster_idxs),peaks(perms_of_dimensions(k,2),current_cluster_idxs),1,cluster_colors(j,:),'filled','DisplayName',sprintf("Cluster %i",j));
                hold on;
            end
            if k==1
                legend();
            end
            if ~isempty(varargin)
                xlabel("Channel "+string(current_channels(perms_of_dimensions(k,1))) +" (in \muV)")
                ylabel("Channel "+string(current_channels(perms_of_dimensions(k,2))) +" (in \muV)")
            end


        end


    end

if isempty(varargin)
    %insert some kind of logic to determine whether we have a blind pass
    %table/peaks/aligned and we'll take actions as appropriate
    what_kind_of_data = "";
else
    what_kind_of_data = varargin{1};
end

if what_kind_of_data=="blind_pass_table"
    %split the blind pass table by its aligned files
    split_table = slice_table_for_parallel_processing(data_to_plot,"fp_to_aligned");
    for i=1:length(split_table)
        current_data = split_table{i};
        aligned = load(current_data{1,"fp_to_aligned"});
        aligned = aligned.data_to_save;
        peaks = get_peaks(aligned,true);
        plot_peaks(peaks,current_data.cluster_idx,current_data{1,"channels"});
    end
elseif what_kind_of_data=="peaks"
    plot_peaks(data_to_plot);
elseif what_kind_of_data == "aligned"
    peaks = get_peaks(data_to_plot,true);
    plot_peaks(peaks)
end
end