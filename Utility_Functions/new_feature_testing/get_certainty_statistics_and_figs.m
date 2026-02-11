function [] = get_certainty_statistics_and_figs(dir_to_nn_sets,config,blind_pass_table,plot_figs,plot_worst_case)
list_of_features_to_add = ["grades 3"];
grades_array = [cell2mat(assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config))];
table_of_nets = struct2table(dir(fullfile(dir_to_nn_sets,"*.mat")));
net_names = string(table_of_nets.name);
split_net_names = split(net_names,"_");
[~,where_below_ends ]= find(split_net_names=="below");
net_nums = arrayfun(@(i) split_net_names(i, where_below_ends(i)+1), ...
    (1:size(split_net_names,1))');

table_of_nets.threshold = str2double(net_nums);
table_of_nets = sortrows(table_of_nets,"threshold","ascend");


true_accuracy = blind_pass_table{:,"accuracy"};
[~,unscaled_certainties ]= get_certainties_of_all_previous_nets(string(table_of_nets.name),dir_to_nn_sets,grades_array);
if plot_figs
    for i=1:height(blind_pass_table)
        figure;
        bar(unscaled_certainties(i,:),1)
        xline(true_accuracy,"True Accuracy"+sprintf("%.2f",true_accuracy))
    end
end
[~,idx_of_lowest] = min(abs(unscaled_certainties),[],2);
distance_from_min_uncertainty = abs(idx_of_lowest-true_accuracy);


disp("Median Distance uncertainty midpoint: "+string(median(distance_from_min_uncertainty)))
figure;
histogram(distance_from_min_uncertainty,"BinEdges",[1:99,100]);
ylabel("Frequency");
xlabel("Distance From Min certainty point")
hold on;
xline(median(distance_from_min_uncertainty),'Label',"median distance from min certainty:"+string(median(distance_from_min_uncertainty)))

[row,~] = find(distance_from_min_uncertainty>90);
if plot_worst_case
    for i=1:length(row)
        f = figure;
        bar(unscaled_certainties(row(i),:),1)
        xline(blind_pass_table{row(i),"accuracy"},'Label',"True Accuracy"+sprintf("%.2f",blind_pass_table{row(i),"accuracy"}))
        title("Min Certainty:"+string(unscaled_certainties(row(i),idx_of_lowest(row(i)))))
        close(f);
    end
end
end