function [all_valid_channel_groups] = build_channel_configs(number_of_channels,config)
%the default channel locations are given by get_probe_xy()
channel_locs = get_probe_xy();
%we'll want to group channels by their distance from each other in sensible
%locations
%the interesting question is how we define sensible
%we know that the 4 channel tetrodes work well so we'll work based off of
%them
first_tetrode = config.ART_TETR_ARRAY(100,:);
%measure the distance between all the arrays
distance_array = zeros(length(first_tetrode),length(first_tetrode));
for i=1:length(first_tetrode)  
    for j=1:length(first_tetrode)
        distance_array(i,j) = vecnorm(channel_locs(i,:)-channel_locs(j,:), 2, 2);
    end
end
row_names = strcat("channel "+string(first_tetrode.'));
col_names = strcat("channel "+string(first_tetrode.'));
distance_table = array2table(distance_array,"RowNames",row_names,"VariableNames",col_names);
disp(distance_table)

sorted_distances = distance_array(:,1);

%we'll calculate the average distance between the choose 3
% upper_bound = sum(distance_array,"all") / length(first_tetrode)-1;

%for each channel we'll build every combination that contains
%number_of_channel without exceeding this upper bound
all_possible_groups = cell(384,1);
og_channels = 1:384;
for i=1:length(all_possible_groups) 
    distances = vecnorm(channel_locs- repmat(channel_locs(i,:),size(channel_locs,1),1), 2, 2);

    [sorted_distances,new_channel_loc] = sort(distances,"ascend");
    channels_by_distance = og_channels(new_channel_loc);
    unique_sorted_distances = unique(sorted_distances);

    %get the n shortest distances 
    %start at 2 because the first one will always be 0
    smallest_n_distances = unique_sorted_distances(2:2+number_of_channels);

    %get all channels that fall within those shortest distances
    channels_within_distance = channels_by_distance(any(sorted_distances<smallest_n_distances.',1));

    %get all combinations of those channsls
    all_possible_groups{i} = nchoosek(channels_within_distance,number_of_channels);
end

all_valid_channel_groups = cell2mat(all_possible_groups);
all_valid_channel_groups = unique(all_valid_channel_groups,'rows');
end