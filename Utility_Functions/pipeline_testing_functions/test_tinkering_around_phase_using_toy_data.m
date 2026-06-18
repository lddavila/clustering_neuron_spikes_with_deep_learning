function [clusters_for_toy_data,dimensions_per_cluster] = test_tinkering_around_phase_using_toy_data(toy_data,ground_truth_idxs,ground_truth_cores,config,all_wf,varargin)
%create tetrodes from the toy data dimensions

if isempty(varargin)
    config.ART_TETR_ARRAY = reshape(1:size(toy_data,2),[],4);
    art_tetr_array = reshape(1:size(toy_data,2),[],4);
else
    config.ART_TETR_ARRAY = varargin{1};
    art_tetr_array = varargin{1};
end
clusters_for_toy_data = cell(size(config.ART_TETR_ARRAY,1),1);
save_img_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"pairs_of_2_plots"));
art_tetr_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(save_img_dir,"tetrode"));
true_core_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(save_img_dir,"ground_truth"));
clustering_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(save_img_dir,"clustering_results"));
dimensions_per_cluster = [];
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

%slice data for parallel processing
sliced_toy_data = cell(size(art_tetr_array,1));
sliced_wf_data = cell(size(art_tetr_array,1));
for i=1:size(art_tetr_array,1)
    sliced_toy_data{i} = abs(toy_data(:,art_tetr_array(i,:)));
    sliced_wf_data{i} = all_wf(art_tetr_array(i,:),:,:);
    disp("finished slicing "+string(i)+"/"+string(size(art_tetr_array,1)));
end

q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = size(config.ART_TETR_ARRAY,1);
print_status_bar(num_iterations,"test_tinkering_around_phase_using_toy_data.m")
parfor i=1:size(config.ART_TETR_ARRAY,1)
    save_name = fullfile(art_tetr_dir,"Tetrode "+string(i));

    cluster_save_name = fullfile(clustering_dir,"Tetrode "+string(i)+".mat");

    if ~isfile(cluster_save_name)
        current_peaks = sliced_toy_data{i}; %get the peaks for the current tetrode
        current_waveforms = sliced_wf_data{i};
        %of these dimensions check how many clusters appear on them
        % number_of_clusters = 0;
        current_waveforms = align_to_peak_ver_2(current_waveforms);
        local_config = config;
        local_config.current_channels = config.ART_TETR_ARRAY(i,:);
        current_channels = config.ART_TETR_ARRAY(i,:);
        % for j=1:length(ground_truth_cores)
        %     if sum(ismember(config.ART_TETR_ARRAY(i,:),ground_truth_cores{j})) >=2
        %         number_of_clusters = number_of_clusters+1;
        %     end
        % end
        % fprintf("# of clusters that appear on this tetrode %i\n",number_of_clusters);
        % fprintf("# of clusters found by dbscan: %i\n",length(unique(clusters_for_toy_data{i}))-1)


        % current_peaks = toy_data(:,config.ART_TETR_ARRAY(i,:));
        z_sc_of_peaks = zscore(max(current_peaks, [], 2));
        the_percentiles = prctile(z_sc_of_peaks,1:100);

        snr_threshs = the_percentiles(config.percentiles_to_use);
        the_subsets = cell(1,length(snr_threshs));
        for j=1:length(snr_threshs)-1
            the_subsets{j} = z_sc_of_peaks > snr_threshs(j);
        end
        the_subsets{end} = ones(size(current_peaks,1),1);
        %we're just using percentiles of z score here not the full pmv, it's just approximated
        tvals = mean(current_peaks) + (std(current_peaks)* config.NUM_OF_STD_ABOVE_MEAN);
        % tvals = [100 105 110 120];
        ir = [100;130;150;100];
        local_clusters = get_clusters_for_toy_data(current_peaks,the_subsets,current_waveforms,local_config.spikesort,local_config,ir,tvals);
        if size(local_clusters,2) > size(local_clusters,1)
            local_clusters = local_clusters.';
        end
        clusters_for_toy_data{i} = local_clusters;
        disp("Finished "+string(i)+"/"+string(size(config.ART_TETR_ARRAY,1)))
        disp(clusters_for_toy_data(i))


        all_comps = nchoosek(1:length(config.ART_TETR_ARRAY(i,:)),2);
        f = figure('units', 'normalized', 'outerposition', [0 0 1 1],'Visible','off');
        tiledlayout("flow");
        cluster_colors = distinguishable_colors(length(clusters_for_toy_data{i}));

        for k=1:size(all_comps,1)
            dim_1 = all_comps(k,1);
            dim_2 = all_comps(k,2);
            x_data = current_peaks(:,dim_1);
            y_data = current_peaks(:,dim_2);

            nexttile;
            scatter(x_data,y_data,3,[0.7 0.7 0.7],'filled','DisplayName',"unclustered");
            hold on;
            for j=1:length(clusters_for_toy_data{i})
                current_cluster_idxs = clusters_for_toy_data{i}{j};
                scatter(x_data(current_cluster_idxs),y_data(current_cluster_idxs),3,cluster_colors(j,:),'filled','DisplayName',"cluster"+string(j));
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
        par_save(cluster_save_name,clusters_for_toy_data{i});
    else
        local_clusters = importdata(cluster_save_name);
        if size(local_clusters,2) > size(local_clusters,1)
            local_clusters = local_clusters.';
        end
        clusters_for_toy_data{i} = local_clusters;
    end
    dimensions_per_cluster = [dimensions_per_cluster;repmat(art_tetr_array(i,:),length(local_clusters),1)];
    send(q,[]);
end

end