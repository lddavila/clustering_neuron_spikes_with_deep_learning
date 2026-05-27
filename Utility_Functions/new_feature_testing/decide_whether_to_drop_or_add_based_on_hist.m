function [] = decide_whether_to_drop_or_add_based_on_hist(histogram_object,dropping,dims_to_drop_or_add,spike_windows,clust_peaks,og_channels,varargin)
%inputs:
%a histogram object created by tinker_around_phase.m, check that function
%to see the exact parameters of the histogram
%dropping
%boolean
%true: you will be dropping a dimension
%false: you will be adding a dimension of data
%data_to_add_or_drop
%data which will be used to modify the grid to see its replacements
%dims_to_drop_or_add
%an array with the channels i.e. dimensions which should be added or
%dropped
%correspond to the third column of spike_windows
%spike windows
%a nx5 array which contains information about the spikes
%col 1: the beginning of the spike
%col 2: the end of the spike
%col 3: the channel which the spike originated from
%col 4: the location of the spike
%col 5: the Median Average Distribution or Z score value wich is was
%originally calculated through the spike detection method

%the general idea behind this function is that when we plot a cluster in a
%2d histogram we get a frequency grid which I hypothesize to be very useful
%the reason I believe it will be useful is because when I add/drop
%dimensions from the cluster I can see how the initial border is affected
%by checking how the added/dropped data affects the histogram grid
%if it makes the area inside the grid denser i.e. increases the bin counts
%inside the border then we can assume combining the new dimension will
%increase cluster accuracy

%conversely if we are dropping a dimension and all the loss is outside of
%the border we want then we can probably assume that the dimension has no
%useful data and we can drop it

%if the new dimension increases the frequency outside of the border than we
%can assume that the new dimension introduces a lot of spikes we do not
%want and thus it will not be a worthwhile dimension to add. Alternatively
%we can keep the spikes that fall inside the border and exclude any spikes
%that fall outside the border


%extract the frequency grid from the histogram object
frequency_grid = histogram_object.BinCounts;

%extract the borders from the histogram object
x_borders = histogram_object.XBinEdges;
y_borders = histogram_object.YBinEdges;

%now the hard part comes from actually establishing the border
%the goal should be to identify the tightest possible border around filled
%squares in the frequency grid
%there are many different ways the data can present itself
%this includes:
%a cluster that is well defined i.e. good edges and frequency that
%peaks toward the middle
%a cluster that does not have a clear center or was divided
%incomplete clusters, i.e. clusters that have a semi circle shape
% border_grid = zeros(size(frequency_grid,1),size(frequency_grid,2));
% beginning_of_grid_x_coord = 0;
% beginning_of_grid_y_coord = 0;
binary_image_of_grid = frequency_grid ~= 0;
% already_visited_grid = zeros(size(frequency_grid,1),size(frequency_grid,2));
% for i=1:size(frequency_grid,1)
%     for j=1:size(frequency_grid,2)
%         %if the current space has no data then just continue without doing
%         %any unnecessary work
%         if (frequency_grid(i,j)==0)
%             continue;
%         end
%         binary_image_of_grid(i,j) =1;
%
%     end
% end




main_cluster_mask = bwareafilt(binary_image_of_grid, 1); %get the "main" cluster

%now depending on whether we are dropping/adding we will take appropriate
%action
if dropping
    all_pers_of_dim = nchoosek(1:size(clust_peaks,1),2);
    cell_array_of_dropped = cell(length(dims_to_drop_or_add),size(all_pers_of_dim,1));
    for perm_counter=1:size(all_pers_of_dim)
        dim_1 = all_pers_of_dim(perm_counter,1);
        dim_2 = all_pers_of_dim(perm_counter,2);
        for dim_counter=1:length(dims_to_drop_or_add)
            %edited_ts = curr_clust_ts(~ismember(spike_windows(:,3),dims_to_drop_or_add(dim_counter)));
            edited_peaks = clust_peaks(:,~ismember(spike_windows(:,3),dims_to_drop_or_add(dim_counter)));
            x_data_edited = edited_peaks(dim_1,:);
            y_data_edited = edited_peaks(dim_2,:);
            new_hist_object = histogram2(x_data_edited,y_data_edited,'XBinEdges',x_borders,'YBinEdges',y_borders,'FaceColor','k');
            new_grid = new_hist_object.BinCounts;
            new_image = new_grid >0;
            cell_array_of_dropped{dim_counter,perm_counter} = new_image;
        end
    end
    if ~isempty(varargin)
        figure;
        imshow(binary_image_of_grid);
        xlabel("Channel "+string(og_channels(1)))
        ylabel("Channel "+string(og_channels(2)))
        title("original Cluster")
        figure;
        imshow(main_cluster_mask);
        title("Main cluster")
        xlabel("Channel "+string(og_channels(1)))
        ylabel("Channel "+string(og_channels(2)))


        cell_array_of_dropped = cell_array_of_dropped.';
        for i=1:size(cell_array_of_dropped,2)
            % figure;
            % tiledlayout("flow");
            for j=1:size(cell_array_of_dropped,1)
                % nexttile();
                figure;
                imshow(cell_array_of_dropped{j,i})
                xlabel("Channel "+string(og_channels(all_pers_of_dim(j,1))));
                ylabel("Channel "+string(og_channels(all_pers_of_dim(j,2))));
                title("After Dropping Channel "+string(dims_to_drop_or_add(i)))
            end
            
        end


    end

end





end