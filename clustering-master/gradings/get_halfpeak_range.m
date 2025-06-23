function [starthalfpk, endhalfpk] = get_halfpeak_range(mean_spike, percent)
    localmins = find_peaks(mean_spike * (-1));
    localmin = localmins{1};
    [peak, peakidx] = max(mean_spike);
    if peak <= 0
        starthalfpk = NaN;
        endhalfpk = NaN;
        return
    end
    peakstart = localmin(find(localmin < peakidx, 1, 'last'));
    if isempty(peakstart)
        peakstart = 1;
    end

    valleyrange = find(mean_spike < mean_spike(peakstart));
    valleyrange = valleyrange(valleyrange > peakstart);
    if isempty(valleyrange)
        peakend = length(mean_spike);
    else
        peakend = valleyrange(1) - 1;
    end

    halfpeakrange = peakstart:peakend;
    halfpeaks = find(mean_spike(halfpeakrange) >= peak * percent);
    starts = find([true (diff(halfpeaks) > 1) true]);
    starthalfpk = NaN;
    endhalfpk = NaN;
    for k = 1:length(starts) - 1
        starthalfpk = halfpeakrange(halfpeaks(starts(k)));
        endhalfpk = halfpeakrange(halfpeaks(starts(k+1) - 1));
        if starthalfpk <= peakidx && peakidx <= endhalfpk
            break
        end
    end
end