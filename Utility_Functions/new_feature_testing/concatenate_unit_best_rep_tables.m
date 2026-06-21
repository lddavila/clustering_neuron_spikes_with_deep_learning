function [table_of_best_rep] = concatenate_unit_best_rep_tables()
dir_to_save_results = "C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\rec_10_unit_app_on_channels";
table_of_all_channel_ratios = struct2table(dir(fullfile(dir_to_save_results,"*.mat")));
table_of_all_channel_ratios.name = string(table_of_all_channel_ratios.name);
table_of_all_channel_ratios.folder = string(table_of_all_channel_ratios.folder);
best_rep_cell_array = cell(height(table_of_all_channel_ratios),1);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = height(table_of_all_channel_ratios);
print_status_bar(num_iterations,"concatenate_unit_best_rep_tables.m")
parfor i=1:height(table_of_all_channel_ratios)

    try
        if isempty(best_rep_cell_array{i})
            current_table = importdata(fullfile(table_of_all_channel_ratios{i,"folder"},table_of_all_channel_ratios{i,"name"}));
            %for every ground truth unit select the top 10 rows
            c1 = current_table{:,"detection_ratio"}>10;
            c2 = current_table{:,"mean_amplitude"} > 30;

            only_current_unit = sortrows(current_table(c1 & c2,:),["detection_ratio","median_amp","mean_amplitude"],"descend");
            only_current_unit.unit = repelem(i,height(only_current_unit),1);
            best_rep_cell_array{i} = only_current_unit;
        end
    catch
    end
    send(q,[]);
end
table_of_best_rep = vertcat(best_rep_cell_array{:});
end