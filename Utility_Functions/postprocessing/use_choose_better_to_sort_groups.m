function [best_rep_array, cell_array_of_groups] = use_choose_better_to_sort_groups(cell_array_of_groups,config)
choose_better_net_struct = importdata(config.FP_TO_COMPLEX_CHOOSE_BETTER_NN);
choose_better_net = choose_better_net_struct.net;
best_rep_array = nan(size(cell_array_of_groups,1),1);
parfor i=1:size(cell_array_of_groups,1)
    [best_rep_array(i),cell_array_of_groups{i}] = bubble_sort_overlapping_clusters(cell_array_of_groups{i},config,choose_better_net)
end
end