function maxidxs = find_peaks(data, include_last)
%FIND_PEAKS Custom function to find peaks in a distribution
    if nargin == 1
        include_last = false;
    end
        data_after = data(:, 3:end);
    diffs = data(:, 2:end-1) > data(:, 1:end-2) & data(:, 2:end-1) >= data_after;
            %this is just logic to see if the values after the peak are greater than hte values before the peak 
            %this matrix then gets anded with checking to see if the data(:,2:end-1) >= the end of the spike 
            %basically it's asking where if there's a peak here
    
    maxidxs = cell(1, size(data, 1));
    for row = 1:size(data, 1)
        maxidxs{row} = find([false; diffs(row, :)'; include_last]);
    end
end