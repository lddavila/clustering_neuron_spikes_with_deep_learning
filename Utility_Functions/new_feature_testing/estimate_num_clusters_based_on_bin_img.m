function [cell_array_of_number_of_clusters,cell_array_of_centers,number_of_perms] = estimate_num_clusters_based_on_bin_img(peaks,channels,varargin)
%plot the peaks in 2d projections and use connected portions as a kind of
%estimate for the # of clusters that are in each 2d projection using matlab
%bwlabel
% num_clusters = 0;
number_of_perms = nchoosek(1:size(peaks,1),2);

if ~isempty(varargin)
    f = figure;
    tiledlayout('flow');
    for i=1:size(number_of_perms,1)
        nexttile();
        dim_1 = number_of_perms(i,1);
        dim_2 = number_of_perms(i,2);
        x_data = peaks(dim_1,:);
        y_data = peaks(dim_2,:);
        scatter(x_data,y_data,'.');
        xlabel("Channel "+string(channels(dim_1)))
        ylabel("Channel "+string(channels(dim_2)))
    end
end
% cell_array_of_images = cell(1,size(number_of_perms,1));
% [compare_wire_1,compare_channel_1] = calculate_the_rep_wire(peaks,channels);
% remaining_wires = setdiff(1:size(peaks,1), compare_wire_1);
% remaining_channels = channels(remaining_wires);

% [relative_wire_2, compare_channel_2] = calculate_the_rep_wire(peaks(remaining_wires,:), remaining_channels);

% compare_wire_2 = remaining_wires(relative_wire_2);
% number_of_perms = [compare_wire_1,compare_wire_2];
min_size = 10; % in pixels
min_bin_size = 0;
cell_array_of_number_of_clusters = zeros(size(number_of_perms,1),1);
cell_array_of_heatmaps = cell(size(number_of_perms,1),1);
cell_array_of_test_images = cell(size(number_of_perms,1),1);
cell_array_of_centers = cell(size(number_of_perms,1),1);
% cell_array_of_clusters = cell(size(number_of_perms,1),1);
for i=1:size(number_of_perms,1)
    dim_1 = number_of_perms(i,1);
    dim_2 = number_of_perms(i,2);
    x_data = peaks(dim_1,:);
    y_data = peaks(dim_2,:);
    if ~isempty(varargin)
        f_1 =figure;
        h= histogram2(x_data,y_data,'XBinEdges',1:1:200,'YBinEdges',1:1:200);
        cell_array_of_heatmaps{i}  = f_1;
        frequency_matrix = h.BinCounts;
        x_bin_edges = h.XBinEdges;
        y_bin_edges = h.YBinEdges;
    else
        [frequency_matrix, x_bin_edges, y_bin_edges] = histcounts2( ...
            x_data, y_data, 1:1:200, 1:1:200);
    end


    %

    image_matrix = frequency_matrix>min_bin_size;
    if ~isempty(varargin)
        f_2 =figure;
        cell_array_of_test_images{i} = f_2;
        imshow(image_matrix);
        title("OG Cluster");
    end
    BW_clean = bwareaopen(image_matrix, min_size);
    L = bwlabel(BW_clean);
    list_of_unique_labels = unique(L);
    list_of_unique_labels(list_of_unique_labels==0) = []; %remove the zero label since its empty space
    % cell_array_of_clusters{i} = list_of_unique_labels;
    cell_array_of_number_of_clusters(i) = length(unique(L))-1;
    current_centers = zeros(length(list_of_unique_labels),2);
    for j=1:length(list_of_unique_labels)
        current_label = list_of_unique_labels(j);
        [row,col] = find(L==current_label);
        rough_center_x = floor(mean(row));
        rough_center_y = floor(mean(col));
        current_centers(j,1) = mean([x_bin_edges(rough_center_x),x_bin_edges(rough_center_x+1)]);
        current_centers(j,2) = mean([y_bin_edges(rough_center_y),y_bin_edges(rough_center_y+1)]);
    end
    cell_array_of_centers{i} = current_centers;
end
% num_clusters = max(cell_array_of_cluster_lengths);
if ~isempty(varargin)
    for i=1:length(cell_array_of_heatmaps)
        try
            close(cell_array_of_test_images{i})
        catch
        end
        try
            close(cell_array_of_heatmaps{i})
        catch
        end
    end
    try
        close(f);
    catch
    end
end
end