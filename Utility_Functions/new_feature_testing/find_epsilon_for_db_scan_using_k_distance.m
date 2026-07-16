function [epsilon,min_num_dpts,res_x] = find_epsilon_for_db_scan_using_k_distance(X,make_plot,normalized)

if ~normalized
    X = zscore(X,1,1);
end
%X should be  nxi
%where each row is an instance
%each column is a feature
min_num_dpts = round(size(X,1) * 0.2);
k_distance = pdist2(X,X,'euclidean','Smallest',min_num_dpts);

kth_distances= sort(k_distance(end,:));

if make_plot
    figure;
    plot(kth_distances, 'LineWidth', 2);
    grid on;
    title(['k-Distance Graph (k = ' num2str(min_num_dpts) ')']);
    xlabel('Points (sorted by distance)');
    ylabel([num2str(min_num_dpts) '-th Nearest Neighbor Distance']);
end

%get the elbow using the kneedle algorithm provided by knee_pt
[res_x, idx_of_result] = knee_pt(kth_distances,1:length(kth_distances));

epsilon = kth_distances(idx_of_result);

end