function [] = plot_units_from_row_of_bp_table(bp_table_row,unit_color_dict,save_dir,number_to_downsample)
rng(0);
f = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
number_of_permutations = nchoosek(1:length(bp_table_row{1,"channels"}),2);
number_of_permutations = [2,4];
aligned = load(bp_table_row{1,"fp_to_aligned"});
aligned = aligned.data_to_save;
aligned = aligned.aligned;
peaks = get_peaks(aligned,true);
tiledlayout(floor(sqrt(size(number_of_permutations,1))),ceil(sqrt(size(number_of_permutations,1))));

legend_string = repelem("",height(bp_table_row),1);
current_channels = bp_table_row{1,"channels"};
unclustred_dpts = setdiff(1:size(peaks,2),vertcat(bp_table_row{:,"cluster_idx"}{:}));

unclustred_dpts = unclustred_dpts(randperm(length(unclustred_dpts),min([number_to_downsample,length(unclustred_dpts)])));
cell_array_of_downsampled_idxs = cell(height(bp_table_row),1);

for i=1:size(number_of_permutations,1)
    nexttile;
    a_plot = scatter(peaks(number_of_permutations(i,1),unclustred_dpts),peaks(number_of_permutations(i,2),unclustred_dpts),20,[0.7 0.7 0.7],'filled');

    hold on;

    for j=1:height(bp_table_row)
        current_cluster_idxs = bp_table_row{j,"cluster_idx"}{1};
        if i==1
            random_cluster_idxs = randperm(length(current_cluster_idxs),min([length(current_cluster_idxs),number_to_downsample]));
            cell_array_of_downsampled_idxs{j} = current_cluster_idxs(random_cluster_idxs);
            current_cluster_idxs = cell_array_of_downsampled_idxs{j};
        else
            current_cluster_idxs = cell_array_of_downsampled_idxs{j};
        end
        legend_string(j) = sprintf("Neuron # %i",bp_table_row{j,"Max_Overlap_Unit"});

        a_plot = scatter(peaks(number_of_permutations(i,1),current_cluster_idxs),peaks(number_of_permutations(i,2),current_cluster_idxs),20,unit_color_dict(bp_table_row{j,"Max_Overlap_Unit"}),'filled');

    end

    % axis off
    % if i==1
    %     legend(legend_string);
    % end
    xlabel("Channel "+string(current_channels(number_of_permutations(i,1))) +" (in \muV)")
    ylabel("Channel "+string(current_channels(number_of_permutations(i,2))) +" (in \muV)")
    ax = gca;
    xticks = ax.XTick; % Current tick positions
    xticklabels = repmat({''}, size(xticks)); % Empty labels
    xticklabels{1} = num2str(xticks(1)); % First label
    xticklabels{end} = num2str(xticks(end)); % Last label

    % Apply new labels
    ax.XTickLabel = xticklabels;
    yticks = ax.YTick;
    yticklabels = repmat({''}, size(yticks));
    yticklabels{1} = num2str(yticks(1));
    yticklabels{end} = num2str(yticks(end));
    ax.YTickLabel = yticklabels;

    set(f, 'Renderer', 'painters');

    title_string = "Clustering Results for Channel Group "+string(strrep(bp_table_row{1,"Tetrode"},"t",""))+" (Channels "+strjoin(string(current_channels))+" Assembled due to physical promxity) with Threshold Multiplier k:"+string(bp_table_row{1,"Z Score"});
    sgtitle(title_string)
    save_name =fullfile(save_dir,bp_table_row{1,"Tetrode"}+" Threshold Multiplier k ="+string(bp_table_row{1,"Z Score"}));
    save_plots_in_all_formats(f,save_name)
    close(f)

end

figure;

all_units = cell2mat(keys(unit_color_dict));


x_loc = [1:5,1:5,1:5,1:5,1:3];
y_loc =zeros(length(all_units)+1,1);
y_loc(6:10) = 1;
y_loc(11:15) = 2;
y_loc(16:20) = 3;
y_loc(21:end) = 4;

scatter(x_loc(end),y_loc(end),40,[.7 .7 .7],'filled');
text(x_loc(end)+0.1,y_loc(end),"unclustered",'FontSize',10,'FontWeight','bold')
hold on;
for j=1:length(x_loc)-1
    scatter(x_loc(j),y_loc(j),40,unit_color_dict(all_units(j)),'filled')
    text(x_loc(j)+0.1,y_loc(j),"Unit "+string(all_units(j)),'FontSize',10,'FontWeight','bold')
end


end
%
% leg = legend([p1, p2], {'Sine', 'Cosine'});
%
% % 2. Create a new blank figure
% fig2 = figure;
%
% % 3. Copy the legend to the new figure
% newLeg = copyobj(leg, fig2);
%
% % 4. Adjust the new legend position to fill the figure
% set(newLeg, 'Position', [0.1 0.1 0.8 0.8]); % [left bottom width height]
% set(newLeg, 'Units', 'normalized'); % Keeps it centered if resized