%edited by Luis David Davila and Alexander Friedman
function the_normal_data = minmax_normalize(the_data, the_min_val, the_max_val)
%MINMAX_NORMALIZE Does min-max normalization all of 'data', regardless of
%the dimensions.
%   normal_data = MINMAX_NORMALIZE(data) returns the normalized data by
%   scaling between 0 and 1.
%
%   normal_data = MINMAX_NORMALIZE(data, min_val, max_val) returns the
%   normalized data by scaling between 'min_val' and 'max_val'.

    if isempty(the_data)
        the_normal_data = the_data;
        return
    end
    
    if nargin < 3
        the_min_val = 0;
        the_max_val = 1;
    elseif the_max_val < the_min_val
        tmp = the_max_val;
        the_max_val = the_min_val;
        the_min_val = tmp;
    end
    
    % Collapses all dimensions into a single one so that we get the min and
    % max of the whole array.
    col_data = the_data(:);
    mindata = min(col_data);
    maxdata = max(col_data);
    
    % Standard formula for min-max normalization by scaling
    the_normal_data = the_min_val + (the_max_val - the_min_val) * (the_data - mindata) / (maxdata - mindata);
end