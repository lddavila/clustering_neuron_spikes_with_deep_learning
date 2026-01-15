function vi = subsample_vr_(vi, nMax)
if numel(vi)>nMax %if there's more data then can be subsampled
    nSkip = floor(numel(vi)/nMax); %define a number which represents the rounded down result of the size of channel data divided by the max number of samples
    %this number will be used to skip datapoints in the channel data
    if nSkip>1, vi = vi(1:nSkip:end); end %subsample the data based on nSkip
    if numel(vi)>nMax %if there are still too many datapoints 
        try
            nRemove = numel(vi) - nMax; %define number of data points to remove 
                                        %these are the extra after nMax has
                                        %been achieved
            viRemove = round(linspace(1, numel(vi), nRemove)); %get nRemove evenly spaced datapoints from the remaining channel data,ensure that they're all whole numbers so they stay idxs of channel data
            viRemove = min(max(viRemove, 1), numel(vi)); 
            vi(viRemove) = []; %remove any that were flagged by the filter
        catch
            % faliure catch, just take the mininmum datapoints required
            % without any fancy filtering
            vi = vi(1:nMax); %take every datapoint from the beginning to nMax
        end
    end
end
end %func