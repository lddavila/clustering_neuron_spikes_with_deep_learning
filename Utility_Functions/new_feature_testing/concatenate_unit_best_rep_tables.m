function [table_of_best_rep] = concatenate_unit_best_rep_tables(dir_to_save_results,varargin)
% if isempty(varargin)
%     % dir_to_save_results = "C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\rec_10_unit_app_on_channels";
% else
%     dir_to_save_results = varargin{1};
% end
table_of_all_channel_ratios = struct2table(dir(fullfile(dir_to_save_results,"*.mat")));
table_of_all_channel_ratios.name = string(table_of_all_channel_ratios.name);
table_of_all_channel_ratios.folder = string(table_of_all_channel_ratios.folder);
best_rep_cell_array = cell(height(table_of_all_channel_ratios),1);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = height(table_of_all_channel_ratios);
print_status_bar(num_iterations,"concatenate_unit_best_rep_tables.m")
all_var_names = [];
is_mismatch = false;
for i=1:height(table_of_all_channel_ratios)

    try
        if isempty(best_rep_cell_array{i})
            to_join_to_table = importdata(fullfile(table_of_all_channel_ratios{i,"folder"},table_of_all_channel_ratios{i,"name"}));

            %for every ground truth unit select the top 10 rows
            c1 = to_join_to_table{:,"detection_ratio"}>10;
            c2 = to_join_to_table{:,"mean_amplitude"} > 30;

            only_current_unit = sortrows(to_join_to_table(c1 & c2,:),["detection_ratio","median_amp","mean_amplitude"],"descend");
            only_current_unit.unit = repelem(i,height(only_current_unit),1);
            local_var_names =string(only_current_unit.Properties.VariableNames);
            if i==1
                var_names = local_var_names;
            else
                if ~all(local_var_names ~= var_names)
                    is_mismatch = true;
                end
            end
            best_rep_cell_array{i} = only_current_unit;
        end
    catch ME
        disp(ME.getReport);
    end
    all_var_names = [all_var_names;local_var_names];
    send(q,[]);
end
if ~is_mismatch && isempty(varargin)
    table_of_best_rep = vertcat(best_rep_cell_array{:});
elseif is_mismatch% && isempty(varargin)
    table_of_best_rep = best_rep_cell_array;
end
% method = varargin{1};
% if method == "construct"
%     joining_keys = varargin{2};
%     all_appearences = [];
%     for i=1:length(best_rep_cell_array)
%         current_rows = best_rep_cell_array{i};
%         all_appearences = [all_appearences;current_rows(:,joining_keys)];
%     end
%     all_appearences = unique(all_appearences,"rows",'stable');
%     table_of_best_rep = [];
%     for j=1:length(best_rep_cell_array)
%         table_of_best_rep  = [table_of_best_rep;innerjoin(all_appearences,best_rep_cell_array{j})];
%     end
% end
end