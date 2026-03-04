function the_data_filt = find_singular_cols(the_data, the_tolerance)
%FIND_SINGULAR_COLS Creates a filter for columns in a matrix to remove
%singular dimensions (essential for mahal to work properly)
    if nargin == 1
        the_tolerance = 0.05;
    end
    the_data_filt = true(1, size(the_data, 2));
    for k = 1:size(the_data, 2)
        dim = the_data(:, k);
        if length(unique(dim)) < the_tolerance * size(the_data, 1)
            the_data_filt(k) = false;
        end
    end
end