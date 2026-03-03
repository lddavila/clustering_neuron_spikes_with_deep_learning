%updated by Luis David Davila and Alexander Friedman
function [the_starthalfpk, the_endhalfpk] = get_halfpeak_range(the_mean_waveform, the_percent)
    localmins = find_peaks(the_mean_waveform * (-1));
    localmin = localmins{1};
    [peak, peakidx] = max(the_mean_waveform);
    if peak <= 0
        the_starthalfpk = NaN;
        the_endhalfpk = NaN;
        return
    end
    peakstart = localmin(find(localmin < peakidx, 1, 'last'));
    if isempty(peakstart)
        peakstart = 1;
    end

    valleyrange = find(the_mean_waveform < the_mean_waveform(peakstart));
    valleyrange = valleyrange(valleyrange > peakstart);
    if isempty(valleyrange)
        peakend = length(the_mean_waveform);
    else
        peakend = valleyrange(1) - 1;
    end

    halfpeakrange = peakstart:peakend;
    halfpeaks = find(the_mean_waveform(halfpeakrange) >= peak * the_percent);
    starts = find([true (diff(halfpeaks) > 1) true]);
    the_starthalfpk = NaN;
    the_endhalfpk = NaN;
    for k = 1:length(starts) - 1
        the_starthalfpk = halfpeakrange(halfpeaks(starts(k)));
        the_endhalfpk = halfpeakrange(halfpeaks(starts(k+1) - 1));
        if the_starthalfpk <= peakidx && peakidx <= the_endhalfpk
            break
        end
    end
end