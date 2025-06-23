function data_filt = find_singular_cols(data, tolerance)
%FIND_SINGULAR_COLS Creates a filter for columns in a matrix to remove
%singular dimensions (essential for mahal to work properly)
    if nargin == 1
        tolerance = 0.05;
    end
    data_filt = true(1, size(data, 2));
    for k = 1:size(data, 2)
        dim = data(:, k);
        if length(unique(dim)) < tolerance * size(data, 1)
            data_filt(k) = false;
        end
    end
end