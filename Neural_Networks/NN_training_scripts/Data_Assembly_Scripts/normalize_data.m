function [normalized_data,cell_array_of_col_min,cell_array_of_col_max] = normalize_data(data_to_normalize,lower_bound,upper_bound)
%data to normalize should be a nested cell array 
%it's structure should match the structure of
%assemble_data_for_neural_net.m
%every item will be scaled between the specified intervals
if isempty(data_to_normalize)
    normalized_data = nan;
    cell_array_of_col_min = nan;
    cell_array_of_col_max = nan;
    return;
end
normalized_data = cell(1,size(data_to_normalize,2));
cell_array_of_col_min = cell(1,size(data_to_normalize,2));
cell_array_of_col_max = cell(1,size(data_to_normalize,2));

for i=1:size(data_to_normalize,2)
    current_data = data_to_normalize{i};
    col_min = min(current_data);
    col_max = max(current_data);
    normalized_data{i} = rescale(current_data,lower_bound,upper_bound,"InputMin",col_min,"InputMax",col_max);
    cell_array_of_col_max = col_max;
    cell_array_of_col_min = col_min;
end

end