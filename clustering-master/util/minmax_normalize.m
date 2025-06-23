function normal_data = minmax_normalize(data, min_val, max_val)
%MINMAX_NORMALIZE Does min-max normalization all of 'data', regardless of
%the dimensions.
%   normal_data = MINMAX_NORMALIZE(data) returns the normalized data by
%   scaling between 0 and 1.
%
%   normal_data = MINMAX_NORMALIZE(data, min_val, max_val) returns the
%   normalized data by scaling between 'min_val' and 'max_val'.

    if isempty(data)
        normal_data = data;
        return
    end
    
    if nargin < 3
        min_val = 0;
        max_val = 1;
    elseif max_val < min_val
        tmp = max_val;
        max_val = min_val;
        min_val = tmp;
    end
    
    % Collapses all dimensions into a single one so that we get the min and
    % max of the whole array.
    col_data = data(:);
    mindata = min(col_data);
    maxdata = max(col_data);
    
    % Standard formula for min-max normalization by scaling
    normal_data = min_val + (max_val - min_val) * (data - mindata) / (maxdata - mindata);
end