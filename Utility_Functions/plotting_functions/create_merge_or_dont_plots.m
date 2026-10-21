close all;clc;
[config,local_figure_dir] = set_up_figure_creation("name_of_calling_file","create_merge_or_dont_plots");
dir_of_poster_data = fullfile(config.data_dir,"data_for_poster_figs");

%get a blind pass table
bp_2_ch = load(fullfile(dir_of_poster_data,"blind_pass_table_2_ch.mat"));
bp_2_ch = bp_2_ch.data_to_save;

%%
%get all representations for max overlap unit
desired_unit = 400;
max_overlap_unit_n = bp_2_ch(bp_2_ch.Max_Overlap_Unit==desired_unit & bp_2_ch.accuracy> 50,:);
%% get the euclidean distance between any 2 waveforms
all_waveforms = cell2mat(max_overlap_unit_n.("mean_waveform_rep_wire_1"));
all_perms = nchoosek(1:size(all_waveforms,1),2);
all_euc_distances = zeros(height(all_perms),1);
for i=1:height(all_perms)
    wf_1 = all_waveforms(all_perms(i,1));
    wf_2 = all_waveforms(all_perms(i,2));
    all_euc_distances(i) = vecnorm(wf_1 - wf_2, 2, 2);
end
all_perms(all_euc_distances==0,:) = [];
all_euc_distances(all_euc_distances==0,:) = [];
[~,index_of_worst_match] = max(all_euc_distances,[],"all");
[~,index_of_best_match] = min(all_euc_distances,[],"all");

best_rows = all_perms(index_of_best_match,:);
worst_rows = all_perms(index_of_worst_match,:);
%% Plot the worst and best examples
distinct_colors = distinguishable_colors(7);
distinct_colors = distinct_colors([1,2,6,7],:);
close all;clc;
the_strings = ["best","worst"];
f = figure('units','normalized','outerposition',[0 0 1 1]);
tiledlayout(1,2,'TileSpacing','tight','Padding','tight');
the_rows_for_best = [];
the_rows_for_worst = [];
for i=1:2
    %get the mean waveforms for the first 2 distinct tetrodes
    [unique_values, first_indices] = unique(bp_2_ch.Tetrode, 'first');
    if the_strings(i)=="best"
        the_data = best_rows;
        euc_to_use = all_euc_distances(index_of_best_match);
        the_rows_for_best = max_overlap_unit_n(the_data,:);
        colors_to_use = distinct_colors([1,2],:);
    else
        the_data = worst_rows;
        euc_to_use = all_euc_distances(index_of_worst_match);
        the_rows_for_worst = max_overlap_unit_n(the_data,:);
        colors_to_use = distinct_colors([3,4],:);
    end

    row_for_mw_1 = max_overlap_unit_n(the_data(1),:);
    row_for_mw_2 = max_overlap_unit_n(the_data(2),:);


    leg_str_1 = sprintf("Mean Waveform For Z Score %i Tetrode %s Cluster %i",row_for_mw_1{1,"Z Score"},row_for_mw_1{1,"Tetrode"},row_for_mw_1{1,"Cluster"});
    leg_str_2 = sprintf("Mean Waveform For Z Score %i Tetrode %s Cluster %i",row_for_mw_2{1,"Z Score"},row_for_mw_2{1,"Tetrode"},row_for_mw_2{1,"Cluster"});
    mw_1 = max_overlap_unit_n{the_data(1),"mean_waveform_rep_wire_1"}{1};
    mw_2 = max_overlap_unit_n{the_data(2),"mean_waveform_rep_wire_1"}{1};


    nexttile();
    plot(mw_1,"DisplayName",leg_str_1,"LineWidth",3,"Color",colors_to_use(1,:));
    hold on;
    plot(mw_2,"DisplayName",leg_str_2,"LineWidth",3,"LineStyle","--","Color",colors_to_use(2,:));
    legend('Location','best')
    row_for_mw_1(:,["Z Score","Tetrode","Cluster","channels","Max_Overlap_Unit","accuracy"])
    row_for_mw_2(:,["Z Score","Tetrode","Cluster","channels","Max_Overlap_Unit","accuracy"])
    title(the_strings(i) +" Euclidean distance: "+euc_to_use);
    xlabel("sampled data points")
    ylabel("Microvolts","Rotation",90)
    remove_tics("figure_to_format",f)
    disp("///////////////////////")
    set(gca, 'Color', 'none'); 
    set(gca, 'FontSize', 20, 'FontName', 'Arial')
    
end
remove_tics("figure_to_format",f);
set(gcf, 'Renderer', 'painters');

% Export using the print command
% print(gcf, fullfile(local_figure_dir, 'min_and_max_euc_dist_plots.pdf'), '-dsvg');
exportgraphics(gcf, fullfile(local_figure_dir, 'my_plot.pdf'), 'ContentType', 'vector', 'Resolution', 300,'BackgroundColor','none')
% %% Create the accompanying cluster plots for the waveforms
% best_aligned_cell_array = cell(1,2);
% worst_aligned_cell_array = cell(1,2);
% config.GT_FP = fullfile(dir_of_poster_data,"ground_truth.mat");
% config.ground_truth_cell_array = importdata(config.GT_FP);
% config.TIMESTAMP_FP =  fullfile(dir_of_poster_data,"timestamps.mat");
% timestamps = importdata(config.TIMESTAMP_FP);
% %% get the aligned data for the matches
% best_aligned_cell_array{1} = importdata(fullfile(dir_of_poster_data,"t24 aligned_to_peak_wf.mat"));
% best_aligned_cell_array{2} = importdata(fullfile(dir_of_poster_data,"t312 aligned_to_peak_wf.mat"));
% %% get the aligned data for the worst matches
% worst_aligned_cell_array{1} = importdata(fullfile(dir_of_poster_data,"t311 aligned_to_peak_wf.mat"));
% worst_aligned_cell_array{2} = importdata(fullfile(dir_of_poster_data,"t314 aligned_to_peak_wf.mat"));

%%
clc;close all;
for i=1:length(the_strings)
    if the_strings(i)=="best"
        peaks_1 = get_peaks(best_aligned_cell_array{1});
        peaks_2 = get_peaks(best_aligned_cell_array{2});
        cluster_1_ts = the_rows_for_best{1,"timestamps"}{1};
        cluster_2_ts = the_rows_for_best{2,"timestamps"}{1};
        cluster_1_idx = the_rows_for_best{1,"cluster_idx"}{1};
        cluster_2_idx = the_rows_for_best{2,"cluster_idx"}{1};
        cluster_1_channels = the_rows_for_best{1,"channels"}{1};
        cluster_2_channels = the_rows_for_best{2,"channels"}{1};
        rows = the_rows_for_best;
        colors_to_use = distinct_colors([1,2],:);

    else
        peaks_1 = get_peaks(worst_aligned_cell_array{1});
        peaks_2 = get_peaks(worst_aligned_cell_array{2});
        cluster_1_ts = the_rows_for_worst{1,"timestamps"}{1};
        cluster_2_ts = the_rows_for_worst{2,"timestamps"}{1};
        rows = the_rows_for_worst;
        cluster_1_idx = the_rows_for_worst{1,"cluster_idx"}{1};
        cluster_2_idx = the_rows_for_worst{2,"cluster_idx"}{1};
        colors_to_use = distinct_colors([3,4],:);
        cluster_1_channels = the_rows_for_worst{1,"channels"}{1};
        cluster_2_channels = the_rows_for_worst{2,"channels"}{1};


    end
    cluster_1_x_label = cluster_1_channels(1);
    cluster_1_y_label = cluster_1_channels(2);
    cluster_2_x_label = cluster_2_channels(1);
    cluster_2_y_label = cluster_2_channels(2);
    channels_for_clust_1 = rows{1,"channels"}{1};
    channels_for_clust_2 = rows{2,"channels"}{1};
    [in_common,~] = ismembertol(cluster_1_ts,cluster_2_ts,0.0002,DataScale=1);
    num_in_common = sum(in_common);

    in_common_set = cluster_1_ts(in_common);
    only_cluster_1_set = cluster_1_ts(~in_common);
    only_cluster_2_set = setdiff(cluster_2_ts,in_common_set);

    figure;
    tiledlayout(3,1,'TileSpacing','compact');


    nexttile()
    xline(in_common_set);
    title("Firing times in common")
    format_poster_fig();

    nexttile()
    if ~isempty(only_cluster_1_set)
        xline(only_cluster_1_set,'Color',colors_to_use(1,:));
    end
    title("Firing times unique to cluster 1")
    format_poster_fig();

    nexttile()
    if ~isempty(only_cluster_2_set)
        xline(only_cluster_2_set,'Color',colors_to_use(2,:));
    end
    title("Firing times unique to cluster 2")
    format_poster_fig();

    xlabel("Time (s)")
    % labels_for_a = repelem("Cluster 1 Timestamps",length(cluster_1_ts),1);
    % labels_for_b = repelem("Cluster 1 Timestamps",length(cluster_2_ts),1);
    % 
    % 
    % % venn(2,'sets',["Cluster 1 Spike Times","Cluster 2 Spike Times"],'alpha',0,'edgeC',[0 0 0],'edgeW',3,'labels',)
    % 
    % data = [num_in_common;length(cluster_1_ts)-num_in_common;length(cluster_2_ts)-num_in_common];
    % names = ["In common","Unique to cluster 1","Unique to cluster 2"];
    % figure;
    % piechart(data,names);
    set(gcf, 'Renderer', 'painters');
    % exportgraphics(gcf, fullfile(local_figure_dir, 'venn'+the_strings(i)+'.pdf'), 'ContentType', 'auto', 'Resolution', 300,'BackgroundColor','none')
    exportgraphics(gcf, fullfile(local_figure_dir, 'time_lines '+the_strings(i)+'.pdf'), 'ContentType', 'vector', 'Resolution', 300,'BackgroundColor','none')
    close all;

    % %the cluster plot
    % f = figure('units','normalized','outerposition',[0 0 1 1]);
    % tiledlayout(1,2,'TileSpacing','tight','Padding','tight');
    % nexttile();
    % scatter(peaks_1(1,:),peaks_1(2,:),3,[0.7,0.7,0.7],'filled')
    % hold on;
    % scatter(peaks_1(1,cluster_1_idx),peaks_1(2,cluster_1_idx),3,colors_to_use(1,:),'filled')
    % xlabel(cluster_1_x_label +" Peaks in microvolts")
    % ylabel(cluster_1_y_label +" Peaks in microvolts")
    % format_poster_fig()
    % 
    % nexttile();
    % scatter(peaks_2(1,:),peaks_2(2,:),3,[.7 .7 .7],'filled')
    % hold on;
    % scatter(peaks_2(1,cluster_2_idx),peaks_2(2,cluster_2_idx),3,colors_to_use(2,:),'filled')
    % xlabel(cluster_1_x_label +" Peaks in microvolts")
    % ylabel(cluster_1_y_label +" Peaks in microvolts")
    % 
    % format_poster_fig()
    % set(gcf, 'Renderer', 'painters');
    % % exportgraphics(gcf, fullfile(local_figure_dir, 'cluster plots '+the_strings(i)+'.pdf'), 'ContentType', 'auto', 'Resolution', 300,'BackgroundColor','none')
    % exportgraphics(gcf, fullfile(local_figure_dir, 'cluster plots '+the_strings(i)+'.pdf'), 'ContentType', 'vector', 'Resolution', 300,'BackgroundColor','none')
end
%% get the line plots for precision/recall/f1 score
odd_recordings =load(fullfile(dir_of_poster_data,"odd_recordings.mat"));
odd_recordings = odd_recordings.odd_recordings;
rec_1_info = importdata(fullfile(dir_of_poster_data,"1_600Neuron300SecondRecordingWithLevel1Noise.mat"));
%%
home_dir =cd("../new_feature_testing");
run_tp_fp_tn_fn_score_calculator_with_hyp_params(odd_recordings,local_figure_dir,rec_1_info);
cd(home_dir)
%% now we create a figure that displays the statistic of showing how successful the group or not pipeline is
%randomly sample 1000 rows of the bp 2 channels
% rng(0)
% bp_2_ch.og_row = (1:1:height(bp_2_ch)).';
% rand_sample_idx = randi(height(bp_2_ch),1000,1);
% rand_rows = bp_2_ch(rand_sample_idx,:);
% all_combos = nchoosek(1:1:height(rand_rows),2);%get all possible comparisons of the 1000 samples
% is_mergable = rand_rows(all_combos(:,1),"Max_Overlap_Unit") == rand_rows(all_combos(:,2),"Max_Overlap_Unit"); %get the true class for all potential merges
% bp_table_file = fullfile(config.base_file_path,"Data","data_for_poster_figs","rand_group_sample.mat");
% par_save(bp_table_file,rand_rows); %save the rand rows as is required by the pipeline
% config.BLIND_PASS_DIR_PRECOMPUTED = fullfile(config.base_file_path,"Data","data_for_poster_figs");
% [~,config,group_cell_array] = run_group_pair_nn_pipeline(bp_table_file,config);%now run the merge or don't pipeline

% now check what the perfect groups would have looked like
% unique_units_in_sample = unique(rand_rows{:,"Max_Overlap_Unit"});
% perfect_groups = cell(1,length(unique_units_in_sample));
% for i=1:length(unique_units_in_sample)
%     perfect_groups{i} = rand_rows(rand_rows{:,"Max_Overlap_Unit"}==unique_units_in_sample(i),:);
% end
%% get info about the groups
% number_of_possible_groups = length(unique_units_in_sample);
% number_of_perfect_groups = 0;
% number_of_corrupted_groups = 0;
% purity_sum = 0;
% corruption_sum = 0;
% for i=1:length(group_cell_array)
%     curr_group = group_cell_array{i};
%     unit_ids = curr_group.Max_Overlap_Unit;
%     c2 = unit_ids == mode(unit_ids);
%     c1 = all(c2);
%     if c1
%         number_of_perfect_groups = number_of_perfect_groups +1;
%     else
%         number_of_corrupted_groups =  number_of_corrupted_groups +1;
%         purity_sum  = purity_sum +(sum(c2) / length(c2));
%         corruption_sum = corruption_sum + (sum(~c2) / length(c2));
%     end
% 
% end
% purity_mean = (purity_sum / (number_of_corrupted_groups) ) * 100;
% corruption_mean = (corruption_sum / (number_of_corrupted_groups))*100;
% fprintf("Number of corrupted groups: %i \n",number_of_corrupted_groups);
% fprintf("Number of pure groups: %i / %i possible pure groups\n",number_of_perfect_groups,number_of_possible_groups);
% fprintf("Mean purity of groups %.2f\n",purity_mean);
% fprintf("Mean corruption of groups %.2f\n",corruption_mean);
% 
% %% now create the actual figure
% f = figure('units','normalized','outerposition',[0 0 1 1]);
% tiledlayout(2,1);
% nexttile();
% data_for_statistic = [number_of_perfect_groups,number_of_corrupted_groups];
% names = ["perfect groups","corrupted_groups"];
% piechart(data_for_statistic,names);
% title("1000 randomly sampled clusters formed "+string(number_of_perfect_groups+number_of_corrupted_groups));
% set(gcf, 'Renderer', 'painters');
% nexttile();
% bar(mean_purity_of_groups)
% exportgraphics(gcf, fullfile(local_figure_dir, 'purity_of_groups.pdf'), 'ContentType', 'auto', 'Resolution', 300)
% 
% 
% 
