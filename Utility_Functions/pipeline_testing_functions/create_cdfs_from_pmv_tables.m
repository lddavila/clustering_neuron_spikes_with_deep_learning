function [table_of_probabilities] = create_cdfs_from_pmv_tables(pmv_table,which_score_to_cdf,slice_by,config,cdfs_or_pdf,some_threshold)
if cdfs_or_pdf=="cdf"
    dir_to_save_cdfs_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"cdfs_for_various_metrics"));
else
    dir_to_save_cdfs_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"pdfs_for_various_metrics"));
end
dir_to_save_whole_plots_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_cdfs_to,"whole_dataset"));
dir_to_save_prc_plots_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_cdfs_to,"perc_split_dataset"));
sliced_data = slice_table_for_parallel_processing(pmv_table,slice_by);
plotting_colors = distinguishable_colors(length(sliced_data));

for j=1:length(which_score_to_cdf)
    disp(which_score_to_cdf(j))
    f_1 = figure('units','normalized','outerposition',[0 0 1 1],'Visible','off');
    ax = axes('Parent', f_1, 'FontSize', 12);
    data_to_cdf = pmv_table.(which_score_to_cdf(j));
    percentile_tracker = pmv_table.percentile;

    if which_score_to_cdf(j)== "precision" || which_score_to_cdf(j)=="f1" || which_score_to_cdf(j)=="recall"
        if which_score_to_cdf(j)=="f1"
            data_to_cdf = cellfun(@transpose,data_to_cdf,'UniformOutput',false);
        end
        size_of_each_data =cell2mat(cellfun(@length, data_to_cdf, 'UniformOutput', false));
        data_to_cdf = cell2mat(data_to_cdf);
        percentile_tracker = cell2mat(arrayfun(@repelem,percentile_tracker,size_of_each_data,ones(length(size_of_each_data),1),'UniformOutput',false));
        z_score = cell2mat(arrayfun(@repelem,pmv_table.z_score,size_of_each_data,ones(length(size_of_each_data),1),'UniformOutput',false));
        %        disp("something")
    else
        percentile_tracker = pmv_table.percentile;
        z_score = pmv_table.z_score;
    end
    discretized_data = discretize(data_to_cdf,0:0.01:1);
    table_to_slice = table(z_score,data_to_cdf,percentile_tracker,discretized_data);
    sliced_data = slice_table_for_parallel_processing(table_to_slice,"z_score");
    save_name = fullfile(dir_to_save_whole_plots_to,which_score_to_cdf(j));

    for i=1:length(sliced_data)
        current_table = sortrows(sliced_data{i},"percentile_tracker","ascend");
        % local_discretized_data = current_table.discretized_data;
        % temp_table = table(current_table.percentile_tracker,local_discretized_data);
        if cdfs_or_pdf=="cdf"
            [f,x] = ecdf(current_table{:,"data_to_cdf"});
            plot(ax,x,f,'LineWidth',2,'Color',plotting_colors(i,:),'DisplayName',"Z Score "+string(current_table{1,slice_by}));
            grid on;
            hold on;
            ylabel(ax,"Cumulative probability");
            title(ax,"CDF of " + which_score_to_cdf(j));
        else
            histogram(ax,current_table{:,"data_to_cdf"},'Normalization','pdf','BinEdges',0:0.01:1,'DisplayName',"Z Score "+string(current_table{1,slice_by}));
            title(ax,"Probability of " + which_score_to_cdf(j));
            hold on;
            ylabel("Probability")
        end
    end
    xlabel(ax,which_score_to_cdf(j));
    legend();

    save_plots_in_all_formats(f_1,save_name);
    close(f_1);
    sliced_data = slice_table_for_parallel_processing(table_to_slice,["percentile_tracker"]);
    save_dir =create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_prc_plots_to,which_score_to_cdf(j)));
   
    num_iterations = length(sliced_data);
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    print_status_bar(num_iterations,"create_cds_from_pmv_tables.m")
    parfor i=1:length(sliced_data)

        local_data = sliced_data{i};
        sliced_yet_again = slice_table_for_parallel_processing(local_data,"z_score");
        f_2 = figure('units','normalized','outerposition',[0 0 1 1],'Visible','off');
        ax_2 = axes('Parent', f_2, 'FontSize', 12);
        save_name = fullfile(save_dir,which_score_to_cdf(j)+" percentile "+string(local_data{1,"percentile_tracker"}) );
        for k=1:length(sliced_yet_again)
            even_more_local_data = sliced_yet_again{k};

            % current_discretized_data = even_more_local_data{:,"discretized_data"};
            if cdfs_or_pdf=="cdf"
                [the_y,the_x] = ecdf(even_more_local_data{:,"data_to_cdf"});
                plot(ax_2,the_x,the_y,'LineWidth',2,'Color',plotting_colors(k,:),'DisplayName',"Z Score "+string(even_more_local_data{1,"z_score"}))
                hold on;
                legend;
                title("CDF of Percentile "+string(even_more_local_data{1,"percentile_tracker"}))
                ylabel(ax_2,"cumulative probability")
            
            else
                histogram(ax_2,even_more_local_data{:,"data_to_cdf"},'Normalization','pdf','BinEdges',0:0.01:1,'DisplayName',"Z Score "+string(even_more_local_data{1,"z_score"}))
                hold on;
                title("PDF of Percentile "+string(even_more_local_data{1,"percentile_tracker"}))
                ylabel("Probability")
            end
            
        end


        xlabel(ax_2,which_score_to_cdf(j) )
        grid on;
        hold on;
        save_plots_in_all_formats(f_2,save_name);
        close(f_2);
        
        
        send(q,[]);
    end
    
end

end