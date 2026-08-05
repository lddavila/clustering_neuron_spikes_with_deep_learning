function [split_table] = try_multiple_clustering_algos_based_on_variance(blind_pass_table,old_peaks,new_peaks,sw,config,make_plots)

    function [cell_array_of_peak_x_vals] = find_number_of_humps_using_find_peaks(even_more_curr_peaks,make_plots)
        if make_plots
            figure;
            tiledlayout("flow");
        end
        cell_array_of_peak_x_vals = cell(size(even_more_curr_peaks,1),1);
        for k=1:size(even_more_curr_peaks,1)
            nexttile();
            bin_edges= (-999:1:1000).';
            pmf = histcounts(even_more_curr_peaks(k,:),'BinEdges',[-1000;bin_edges],'Normalization','pdf');
            [pk,loc_of_pk] = findpeaks(pmf,'MinPeakDistance',50);
            cell_array_of_peak_x_vals{k} = (bin_edges(loc_of_pk));

            if make_plots

                plot(bin_edges,pmf.');
                hold on;
                scatter(bin_edges(loc_of_pk),pk,10,'black','filled','o');
                xlabel("Amplitude in \mu V")
                ylabel("Probability")
                title("PDF of cluster along dimension "+string(k))
            end
        end
    end
    function [cell_array_of_per_dimension_means,cell_array_of_per_dimension_sigmas] = find_number_of_humps_using_gmdistribution(peaks)
        max_components = 10;


        % Loop and fit multiple models along each dimension
        cell_array_of_per_dimension_means = cell(size(peaks,1),1);
        cell_array_of_per_dimension_sigmas = cell(size(peaks,1),1);
        num_iterations = size(peaks,1) * max_components;
        q = parallel.pool.DataQueue;
        afterEach(q,@print_status_bar)
        print_status_bar(num_iterations,"find_number_of_humps_using_gmdistribution");
        parfor p=1:size(peaks,1)
            warning_state = warning("off", "stats:gmdistribution:FailedToConverge"); %known warning which will not affect results
            restore_warning = onCleanup(@() warning(warning_state));
            data = peaks(p,:);
            bic_scores = zeros(1, max_components);
            gmm_models = cell(1, max_components);
            for k = 1:max_components
                try
                    gmm_models{k} = fitgmdist(data', k, 'RegularizationValue', 0.01);
                    bic_scores(k) = gmm_models{k}.BIC;
                catch
                    bic_scores(k) = Inf; % Handle convergence failures
                end
                send(q,[]);
            end
            % Pick the model with the lowest BIC score
            [~, best_k] = min(bic_scores);
            best_gmm = gmm_models{best_k};
            cell_array_of_per_dimension_means{p} = best_gmm.mu;
            cell_array_of_per_dimension_sigmas{p} = best_gmm.Sigma;
            % fprintf('Optimal number of humps found: %d\n', best_k);

        end
        clear restore_warning  % Restores the previous warning state
    end

    function [] = plot_the_new_clusters(peaks,cluster_idx)
    end
    function [new_blind_pass_table] = assemble_into_blind_pass_table(cell_array_of_cluster_results,timestamps,methods)
        new_blind_pass_table = [];
        method = [];
        cluster = [];
        cell_arr_of_ts = cell(length(cell_array_of_cluster_results),1);
        for k=1:length(cell_array_of_cluster_results)
            curr_clust_idx = cell_array_of_cluster_results{k};
            cluster_list = unique(curr_clust_idx);
            something_local = cell(length(cluster_list),1);
            cluster= [cluster;cluster_list];
            for p=1:length(cluster_list)
                something_local{p} = timestamps(cluster_list(p)==curr_clust_idx);
                
            end
            method = [method;repelem(methods(k),length(cluster_list),1)];
            cell_arr_of_ts{k} = something_local;
        end
       
        new_something_or_other = vertcat(cell_arr_of_ts(:));
        
        new_blind_pass_table = table(method,cluster,vertcat(cell_arr_of_ts{:}),'VariableNames',["method","cluster","timestamps"]);
        
    end
    function [new_blind_pass_table] = run_all_clustering_algos(even_more_curr_peaks,cluster_center,gm,timestamps)
        cell_array_of_cluster_results = cell(1,4);
        method = ["kmedoids","kmeans","dbscan","spectralcluster"];
        num_cl = size(cluster_center,2);
        cell_array_of_cluster_results{1}  = kmedoids(even_more_curr_peaks.',num_cl,"Start",cluster_center.');
        cell_array_of_cluster_results{2} = kmeans(even_more_curr_peaks.',num_cl,'Start',cluster_center.');
        cell_array_of_cluster_results{3} = dbscan(even_more_curr_peaks.',10,20);
        % cell_array_of_cluster_results{4} = cluster(gm,even_more_curr_peaks.');
        cell_array_of_cluster_results{4} = spectralcluster(even_more_curr_peaks.',num_cl);

        new_blind_pass_table = assemble_into_blind_pass_table(cell_array_of_cluster_results,timestamps,method);
    end
timestamps = importdata(config.TIMESTAMP_FP);
split_table = [];
for i=1:height(blind_pass_table)
    curr_peaks = new_peaks{i};
    curr_sw = sw{i};
    for j=1:length(curr_peaks)
        even_more_curr_peaks = curr_peaks{j};
        if isempty(even_more_curr_peaks)
            continue;
        end
        even_more_curr_peaks = abs(even_more_curr_peaks(:,blind_pass_table{i,"cluster_idx"}{1}));


        % cell_array_of_peak_x_vals = find_number_of_humps_using_find_peaks(even_more_curr_peaks,make_plots);
        find_number_of_humps_using_find_peaks(even_more_curr_peaks,make_plots);
        [cluster_centers,cluster_sigmas ] = find_number_of_humps_using_gmdistribution(even_more_curr_peaks);

        [~,rows_of_centers] = find_pmfs_closest_real_observation_in_data(cluster_centers(end),cluster_sigmas(end),even_more_curr_peaks(end,:));
        cluster_center = even_more_curr_peaks(:,rows_of_centers);


        new_blind_pass_table = run_all_clustering_algos(even_more_curr_peaks,cluster_center,[],blind_pass_table{i,"timestamps"}{1});

        
        new_blind_pass_table = add_overlap_percentage_col_and_max_overlap_unit_optimized(new_blind_pass_table,config,timestamps);
        new_blind_pass_table = add_accuracy_col(config,new_blind_pass_table);
        disp("before accuracy");
        disp(blind_pass_table(i,["accuracy","Max_Overlap_Unit","timestamps"]));
        disp("new accuracy");
        new_blind_pass_table = sortrows(new_blind_pass_table,["method","accuracy"],"descend");
        new_blind_pass_table.cluster_size = cellfun(@length,new_blind_pass_table.timestamps);
        disp(new_blind_pass_table(:,["method","cluster","Max_Overlap_Unit","accuracy","tp","fp","fn","cluster_size"]));
        new_blind_pass_table.og_cluster = repelem(join(blind_pass_table{i,["Z Score","Tetrode","Cluster"]}),height(new_blind_pass_table),1);
        
        disp("###########################################################")
        split_table = [split_table;new_blind_pass_table];
    end

end
end