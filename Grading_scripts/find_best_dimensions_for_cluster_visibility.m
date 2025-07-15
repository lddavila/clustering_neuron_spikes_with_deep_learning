function [min_b_dist_among_highest_mean_b_dist,which_dim_were_best] = find_best_dimensions_for_cluster_visibility(all_peaks,cluster_idx,current_cluster)
list_of_all_dimensions = 1:size(all_peaks,1);
mean_bhat_of_varying_number_of_dimensions = []; %in an example with 4 dimensions this should have a lenght of 15
bhat_distances_for_varying_number_of_dimensions = {}; %in an example with 4 dimensions this should have a length of 15
the_various_dimensions = {}; %in an example with 4 dimensions this should have a length of 15
all_peaks = all_peaks.';
if isempty(all_peaks)
    min_b_dist_among_highest_mean_b_dist = 0;
    which_dim_were_best = NaN;
end
for k = 1:1.5%size(all_peaks,2)
    all_comb_for_k_dimensions = nchoosek(list_of_all_dimensions,k);
    for current_combination = 1:size(all_comb_for_k_dimensions,1)
        curr_clust_in_curr_dim_comb = all_peaks(cluster_idx{current_cluster},all_comb_for_k_dimensions(current_combination,:));
        labels_for_curr_clut = boolean(zeros(size(curr_clust_in_curr_dim_comb,1),1)+1);
        bhat_dist_for_current_dim_cur_clust = [];
        for cluster_counter=1:length(cluster_idx)
            if cluster_counter==current_cluster || size(cluster_idx{cluster_counter},1) <=100
                continue
            end
            comp_clust_in_curr_dim_comb = all_peaks(cluster_idx{cluster_counter},all_comb_for_k_dimensions(current_combination,:));
            labels_for_com_clust = boolean(zeros(size(comp_clust_in_curr_dim_comb,1),1));
            bhat_dist_from_current_clust_to_comp_clust = bhattacharyyaDistance([curr_clust_in_curr_dim_comb;comp_clust_in_curr_dim_comb],[labels_for_curr_clut;labels_for_com_clust]);

            [weights,idx]  = correlationWeightedScore([curr_clust_in_curr_dim_comb;comp_clust_in_curr_dim_comb],bhat_dist_from_current_clust_to_comp_clust,1);
            weighted_mean_b_dist = bhat_dist_from_current_clust_to_comp_clust * weights.';
            bhat_dist_for_current_dim_cur_clust = [bhat_dist_for_current_dim_cur_clust;bhat_dist_from_current_clust_to_comp_clust];

        end
        bhat_distances_for_varying_number_of_dimensions{end+1} = bhat_dist_for_current_dim_cur_clust;
        mean_bhat_of_varying_number_of_dimensions = [mean_bhat_of_varying_number_of_dimensions;mean(bhat_dist_for_current_dim_cur_clust,"all")];
        the_various_dimensions{end+1} = all_comb_for_k_dimensions(current_combination,:);
    end

end

[~,Index_of_max_mean] = max(mean_bhat_of_varying_number_of_dimensions);
dimensions_with_highest_bhat_distance = bhat_distances_for_varying_number_of_dimensions{Index_of_max_mean};
which_dim_were_best = the_various_dimensions{Index_of_max_mean};
[min_b_dist_among_highest_mean_b_dist,Index_of_min]= min(dimensions_with_highest_bhat_distance);

if isempty(min_b_dist_among_highest_mean_b_dist)
    min_b_dist_among_highest_mean_b_dist = 0;
    which_dim_were_best = NaN;
end
if size(which_dim_were_best,2) > 1
    disp("multi dim is greater")
end
end