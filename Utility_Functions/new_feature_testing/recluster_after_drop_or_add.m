function [all_idxs,f] = recluster_after_drop_or_add(peaks,cell_array_of_number_of_clusters,config,testing,channels,old_ts,perms,cell_array_of_cluster_centers,varargin)
if testing
    f = figure('units','normalized','outerposition',[0 0 1 1],'Visible','off');
    tiledlayout('flow');
end
for j=1:length(cell_array_of_number_of_clusters)

    num_clusters = cell_array_of_number_of_clusters(j);
    cluster_centers =cell_array_of_cluster_centers{j};
    [the_center, the_U_value, the_mpc_value] = hfcm_modded_for_new_dim_clust(peaks([perms(j,1),perms(j,2)],:).', num_clusters, config.spikesort,cluster_centers);
    new_ts = cell(size(the_U_value,2),1);
    all_idxs = cell(size(the_U_value,2),1);
    max_u = max(the_U_value);
    % new_ts = cell(num_clusters);
    for i=1:size(the_U_value,1)
        all_idxs{i} = find(the_U_value(i,:)==max_u);

        new_ts{i} = old_ts(all_idxs{i});
    end

    if testing
        clust_colors = distinguishable_colors(size(the_U_value,1));
        nexttile();
        dim_1 = perms(j,1);
        dim_2 = perms(j,2);
        for i=1:size(the_U_value,1)
            if ~isempty(varargin)
                blind_pass_table = table(new_ts(i),'VariableNames',["timestamps"]);
                blind_pass_table = add_overlap_percentage_col_and_max_overlap_unit_optimized(blind_pass_table,config,varargin{1});
                [blind_pass_table,matches]= add_accuracy_col(config,blind_pass_table);
                acc = blind_pass_table{1,"accuracy"};
                unit = blind_pass_table{1,"Max_Overlap_Unit"};
                scatter(peaks(dim_1,all_idxs{i}),peaks(dim_2,all_idxs{i}),'.','DisplayName',"Cluster "+string(i)+" acc: "+sprintf('%.2f',acc) +" size: "+sprintf('%i',length(new_ts{i})) +" Neur:"+string(unit)+" TP:"+string(matches),'MarkerFaceColor',clust_colors(i,:));
            else
                scatter(peaks(dim_1,all_idxs{i}),peaks(dim_2,all_idxs{i}),'.','DisplayName',"Cluster "+string(i),'MarkerFaceColor',clust_colors(i,:)+"size: "+sprintf('%i',length(new_ts{i})));
            end
            hold on;

            scatter(the_center(:,1),the_center(:,2),500,"xk","DisplayName","",'HandleVisibility','off','LineWidth',5);
            xlabel("channel " + string(channels(dim_1)))
            ylabel("channel " + string(channels(dim_2)))
            legend('Location','best')
        end
    end
end

end

