%this file has been edited by Luis D. Davila and Alexander Friedman 
function [the_dim_filter, the_num_good_dims] = select_dimensions_dip(the_data, the_new_config)
%SELECT_DIMENSIONS_DIP Creates a filter based on separability between
%distributions in each dimension
%   [dim_filter, num_good_dims] = SELECT_DIMENSIONS_DIP(data) returns the
%   logical indices corresponding to features that pass the overlap test,
%   as well as the number of features which were considered "good."

    the_dim_filter = false(1, size(the_data, 2));
    the_num_good_dims = 0;
    for k = 1:size(the_data, 2)
        dim = the_data(:, k);
        [passed, good] = overlap_test(dim, the_new_config,k);
        if passed
            the_dim_filter(k) = true;
            if good
                the_num_good_dims = the_num_good_dims + 1;
            end
        end
    end
end