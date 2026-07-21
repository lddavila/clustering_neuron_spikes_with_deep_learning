function [sizes] = get_nested_cell_size(C)
if ~iscell(C)
    % Recursively apply to every element in the cell array
    sizes = length(C);
else
    % Return the size of the final leaf data
    sizes = cellfun(@get_nested_cell_size, C, 'UniformOutput', false);
end
end