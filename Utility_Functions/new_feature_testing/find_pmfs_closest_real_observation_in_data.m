function [real_cluster_center,rows_of_cluster_center] = find_pmfs_closest_real_observation_in_data(cell_array_of_cluster_means,cell_array_of_cluster_std,peaks)
%first find the bounds for every cluster by using mean +-2*std

% all_bounds = cell(length(cell_array_of_cluster_std),1);
% for i=1:length(cell_array_of_cluster_std)
%     the_means = cell_array_of_cluster_means{i};
%     the_stds = sqrt(vertcat(cell_array_of_cluster_std{i}(:)));
%     all_bounds{i} = [the_means - 2*(the_stds),the_means + 2*(the_stds)];
% end

%now for each cluster identify the closest actual data point to the its
%mean and get that data points partner values in all n dimensions of peaks
cell_array_of_closest_real_datapoint = cell(length(cell_array_of_cluster_means),1);
rows_of_cluster_center = cell(length(cell_array_of_cluster_means),1);
for i=1:length(cell_array_of_closest_real_datapoint)
    % local_peaks = peaks(i,:).';
    [~,places ]= sort(abs(peaks.'-cell_array_of_cluster_means{i}.'),'ascend');
    rows_of_cluster_center{i} = (places(1,:));
    % real_data_point = peaks(:,closest_row);
    cell_array_of_closest_real_datapoint{i} = peaks(:,rows_of_cluster_center{i}).';
end

real_cluster_center = cell2mat(cell_array_of_closest_real_datapoint);
rows_of_cluster_center = cell2mat(rows_of_cluster_center);
% %now check if any of the cluster centers are within the bounds of a cluster
% %that appears in another dimension so we can coordinate with which
% clusters across dimensions
% total_num_clusters = cell2mat(cellfun(@size,cell_array_of_closest_real_datapoint,'UniformOutput',false));
% clusters_that_are_the_same = eye(sum(total_num_clusters(:,1)));
% all_bounds = cell2mat(all_bounds);
% 
% all_means_as_array = cell2mat(cell_array_of_cluster_means);
% for i=1:size(all_bounds,1)
%     comparison_mean = all_means_as_array(i,:);
%     for j=1:size(all_bounds,1)
%         if comparison_mean >= all_bounds(j,1) && comparison_mean <= all_bounds(j,2)
%             clusters_that_are_the_same(i,j) = true;
%             clusters_that_are_the_same(j,i) = true;
%         end
%     end
% end



end