%edited by Luis David Davila and Alexander Friedman
function the_maxidxs = find_peaks(the_data, the_include_last)
%FIND_PEAKS Custom function to find peaks in a distribution
    if nargin == 1
        the_include_last = false;
    end
        data_after = the_data(:, 3:end);
    diffs = the_data(:, 2:end-1) > the_data(:, 1:end-2) & the_data(:, 2:end-1) >= data_after;
            %this is just logic to see if the values after the peak are greater than hte values before the peak 
            %this matrix then gets anded with checking to see if the data(:,2:end-1) >= the end of the spike 
            %basically it's asking where if there's a peak here
    
    the_maxidxs = cell(1, size(the_data, 1));
    for row = 1:size(the_data, 1)
        the_maxidxs{row} = find([false; diffs(row, :)'; the_include_last]);
    end
end