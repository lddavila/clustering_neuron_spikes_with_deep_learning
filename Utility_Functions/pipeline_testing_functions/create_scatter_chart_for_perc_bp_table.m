function [table_of_percentiles] = create_scatter_chart_for_perc_bp_table(split_plots,varargin)
dir_with_tables = "E:\prc_test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\DEBUG\ACCURACY";
dir_with_tables = "E:\prc_2_test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\DEBUG\ACCURACY";
table_of_percent_tables = struct2table(dir(fullfile(dir_with_tables,"*_bp_table*")));
table_of_percent_tables.folder = string(table_of_percent_tables.folder);
table_of_percent_tables.name = string(table_of_percent_tables.name);
table_of_percentiles = [];

if isempty(varargin)
    parfor i=1:height(table_of_percent_tables)
        try
            current_name = table_of_percent_tables{i,"name"};
            the_local_table = importdata(fullfile(table_of_percent_tables{i,"folder"},current_name));
            prctiles_used = the_local_table.prctile_used;

            the_local_table = the_local_table.blind_pass_table;
            the_local_table.prctiles_used = repmat(prctiles_used,size(the_local_table,1),1);
            table_of_percentiles = [table_of_percentiles;the_local_table];
        catch
            disp("caught");
        end
        fprintf("Finished %i/%i\n",i,height(table_of_percent_tables))
    end
else
    table_of_percentiles = varargin{1};
end

unique_prctiles = unique(table_of_percentiles.prctiles_used,"rows");
unique_tetrodes = unique(table_of_percentiles{:,"Tetrode"});
unique_mults = unique(table_of_percentiles{:,"Multiplier"});

colors_to_use = distinguishable_colors(length(unique_mults));

for k=1:length(unique_tetrodes)
    current_tetrode = unique_tetrodes(k);
    if ~split_plots
        figure;
    end
    legend_string = [];
    places_to_draw_grid_lines = [];
    labels = join(string(unique_prctiles), "\_",2);
    scatter_array = [];
    for j=1:length(unique_mults)
        current_mult = unique_mults(j);

        
        all_accuracy = [];
        all_cluster_colors = [];
        number_of_clusters_to_plot = [];
        legend_string = [legend_string,"Multiplier "+string(current_mult)];

        % for i = 1:size(unique_prctiles,1)
            if split_plots
                figure;
            end
            


            % c1 = all(table_of_percentiles{:,"prctiles_used"} == current_percentiles, 2);
            c2 = table_of_percentiles{:,"Multiplier"} ==current_mult;
            c3 = table_of_percentiles{:,"Tetrode"} == current_tetrode;
            rows = table_of_percentiles(c2 & c3, :);

      
            [tf, loc] = ismember(rows.prctiles_used, unique_prctiles, 'rows');

            all_x = loc;
            all_accuracy = rows.accuracy;
            % all_cluster_size = [all_cluster_size; cluster_size];
            

            all_cluster_colors = repmat(colors_to_use(find(current_mult==unique_mults),:),height(rows),1);

            number_of_clusters_to_plot = [number_of_clusters_to_plot,string(height(rows))];
            
            
            
            s = scatter(all_x, all_accuracy, repelem(100,length(all_x),1),all_cluster_colors, ...
                'filled', 'MarkerFaceAlpha', 0.55);
            scatter_array = [scatter_array,s];
            if ~split_plots
                hold on;
            else
                legend(scatter_array,legend_string);
                places_to_draw_grid_lines =1:size(unique_prctiles,1) +1;
                xline(all_x+0.5,'HandleVisibility','off');

                xticks(1:numel(labels))
                xticklabels(labels)
                xtickangle(45)
                yline(0:10:100,'HandleVisibility','off')
                xlabel("PMV Percentile Window")
                ylabel("Cluster Accuracy")
                scatter_array = [];
                legend_string = [];
                title(current_tetrode + " Multiplier: "+string(current_mult) +" | "+string(length(all_accuracy))+" Clusters found" )
            end
        % end
    end
    close all;
    if ~split_plots

        legend(scatter_array,legend_string);
        % text(places_to_draw_grid_lines,repelem(95,1,length(places_to_draw_grid_lines)),number_of_clusters_to_plot);
        xline(places_to_draw_grid_lines,'HandleVisibility','off')

        xticks(1:numel(labels))
        xticklabels(labels)
        xtickangle(45)
        yline(0:10:100,'HandleVisibility','off')
        xlabel("PMV Percentile Window")
        ylabel("Cluster Accuracy")
        % title("Cluster Accuracy by PMV Percentile Window "+string(table_of_percentiles{1,"Tetrode"})+" Multiplier "+string(current_mult)+" # Clusters: "+string(length(all_accuracy)))

        title(current_tetrode + " Multiplier: "+string(current_mult) +" | "+string(length(all_accuracy))+" Clusters found" )
    end

end
end