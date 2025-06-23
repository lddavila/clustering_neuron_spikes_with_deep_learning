function [dim_filter, num_good_dims] = select_dimensions_dip(data, config)
%SELECT_DIMENSIONS_DIP Creates a filter based on separability between
%distributions in each dimension
%   [dim_filter, num_good_dims] = SELECT_DIMENSIONS_DIP(data) returns the
%   logical indices corresponding to features that pass the overlap test,
%   as well as the number of features which were considered "good."

    dim_filter = false(1, size(data, 2));
    num_good_dims = 0;
    for k = 1:size(data, 2)
        dim = data(:, k);
        [passed, good] = overlap_test(dim, config,k);
        if passed
            dim_filter(k) = true;
            if good
                num_good_dims = num_good_dims + 1;
            end
        end
    end
end