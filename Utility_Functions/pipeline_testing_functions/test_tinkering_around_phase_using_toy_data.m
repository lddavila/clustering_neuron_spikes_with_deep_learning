function [clusters_for_toy_data,dimensions_per_cluster] = test_tinkering_around_phase_using_toy_data(toy_data,ground_truth_idxs,ground_truth_cores,config,art_tetr_array,save_img_dir,dir_with_sliced_data)
%create tetrodes from the toy data dimensions

clusters_for_toy_data = cell(size(art_tetr_array,1),1);

art_tetr_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(save_img_dir,"tetrode"));
true_core_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(save_img_dir,"ground_truth"));
clustering_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(save_img_dir,"clustering_results"));
dimensions_per_cluster = [];
poolobj = parpool("Processes",8);
for i=1:length(ground_truth_idxs)
    save_name = fullfile(true_core_dir,"Cluster "+string(i));
    if isfile(save_name+".png")
        continue;
    end
    gt_cores = ground_truth_cores{i};
    all_comps = nchoosek(1:length(gt_cores),2);
    f = figure('units', 'normalized', 'outerposition', [0 0 1 1],'Visible','off');
    tiledlayout("flow");
    % cluster_colors = distinguishable_colors(length(ground_truth_cores));

    current_peaks = abs(toy_data(:,gt_cores));
    current_channels = gt_cores;
    for k=1:size(all_comps,1)
        dim_1 = all_comps(k,1);
        dim_2 = all_comps(k,2);
        x_data = current_peaks(:,dim_1);
        y_data = current_peaks(:,dim_2);

        nexttile;
        scatter(x_data,y_data,3,[0.7 0.7 0.7],'filled');
        hold on;
        scatter(x_data(ground_truth_idxs{i}),y_data(ground_truth_idxs{i}),3,"black","filled");
        xlabel("simulated dimension "+string(current_channels(dim_1)) +" (in \muV)")
        ylabel("simulated dimension "+string(current_channels(dim_2)) +" (in \muV)")



    end
    save_plots_in_all_formats(f,save_name);
    close(f);
    disp(i);
end


% dir_with_sliced_data = varargin{3};
temp_table = table(art_tetr_array(:,1),art_tetr_array(:,2),"VariableNames",["dim_1","dim_2"]);
sliced_temp_table = slice_table_for_parallel_processing(temp_table,"dim_1");


q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = size(art_tetr_array,1);


print_status_bar(num_iterations,"test_tinkering_around_phase_using_toy_data.m")
starting_point=1;
for i=1:length(sliced_temp_table)

    current_data = sliced_temp_table{i};

    dim_1 = current_data{1,"dim_1"};
    dim_1_struct = load(fullfile(dir_with_sliced_data,"dim_"+string(dim_1)+".mat"),"data_struct");
    dim_1_struct = dim_1_struct.data_struct;
    local_clusters_for_toy_data = cell(height(current_data),1);
    local_dims_per_cluster = cell(height(current_data),1);
    dim_1_struct_parallel = parallel.pool.Constant(dim_1_struct);
    parfor j=1:height(current_data)
        current_channels = current_data{j,:};
        first_dim = current_channels(1);
        dim_2 = current_channels(2);
        save_name = fullfile(art_tetr_dir,"dims_"+string(first_dim)+"_"+string(dim_2));
        cluster_save_name = fullfile(clustering_dir,"dims_"+string(first_dim)+"_"+string(dim_2)+".mat");
        

        if ~isfile(cluster_save_name)
            dim_2_struct = load(fullfile(dir_with_sliced_data,"dim_"+string(dim_2)+".mat"),"data_struct");
            dim_2_struct = dim_2_struct.data_struct;
            current_peaks = [dim_1_struct_parallel.Value.peaks,dim_2_struct.peaks];
            current_waveforms = [dim_1_struct_parallel.Value.wf;dim_2_struct.wf];

            %of these dimensions check how many clusters appear on them
            % number_of_clusters = 0;
            current_waveforms = align_to_peak_ver_2(current_waveforms);
            local_config = config;
            local_config.current_channels = current_data{j,:};
            


            % current_peaks = toy_data(:,config.ART_TETR_ARRAY(i,:));
            z_sc_of_peaks = zscore(max(current_peaks, [], 2));
            the_percentiles = prctile(z_sc_of_peaks,1:100);

            snr_threshs = the_percentiles(config.percentiles_to_use);
            the_subsets = cell(1,length(snr_threshs));
            for s=1:length(snr_threshs)-1
                the_subsets{s} = z_sc_of_peaks > snr_threshs(s);
            end
            the_subsets{end} = ones(size(current_peaks,1),1);
            %we're just using percentiles of z score here not the full pmv, it's just approximated
            tvals = mean(current_peaks) + (std(current_peaks)* config.NUM_OF_STD_ABOVE_MEAN);
            % tvals = [100 105 110 120];

            ir = [100;130];

            local_clusters = get_clusters_for_toy_data(current_peaks,the_subsets,current_waveforms,local_config.spikesort,local_config,ir,tvals);
            if size(local_clusters,2) > size(local_clusters,1)
                local_clusters = local_clusters.';
            end
            local_clusters_for_toy_data{j} = local_clusters;


            all_comps = [1,2];%nchoosek(1:length(config.ART_TETR_ARRAY(i,:)),2);
            f = figure('units', 'normalized', 'outerposition', [0 0 1 1],'Visible','off');
            tiledlayout("flow");
            cluster_colors = distinguishable_colors(length(local_clusters_for_toy_data{j}));

            for k=1:size(all_comps,1)
                dim_1 = all_comps(k,1);
                dim_2 = all_comps(k,2);
                x_data = current_peaks(:,dim_1);
                y_data = current_peaks(:,dim_2);

                nexttile;
                scatter(x_data,y_data,3,[0.7 0.7 0.7],'filled','DisplayName',"unclustered");
                hold on;
                for c=1:length(local_clusters_for_toy_data{j})
                    current_cluster_idxs = local_clusters_for_toy_data{j}{c};
                    scatter(x_data(current_cluster_idxs),y_data(current_cluster_idxs),3,cluster_colors(c,:),'filled','DisplayName',"cluster"+string(c));
                    hold on;
                end
                xlabel("simulated dimension "+string(current_channels(dim_1)) +" (in \muV)")
                ylabel("simulated dimension "+string(current_channels(dim_2)) +" (in \muV)")

                if k==size(all_comps,1)
                    legend;
                end


            end
            save_plots_in_all_formats(f,save_name);
            close(f);
            par_save(cluster_save_name,local_clusters_for_toy_data{j});
        else
            local_clusters = importdata(cluster_save_name);
            if size(local_clusters,2) > size(local_clusters,1)
                local_clusters = local_clusters.';
            end
            local_clusters_for_toy_data{j} = local_clusters;
        end
        local_dims_per_cluster{j} = repmat(current_channels,length(local_clusters),1);

        send(q,[]);
    end
    dimensions_per_cluster = [dimensions_per_cluster;vertcat(local_dims_per_cluster{:})];
    clusters_for_toy_data(starting_point:(starting_point+height(current_data))-1) = local_clusters_for_toy_data;
    starting_point = starting_point + height(current_data);


end

end