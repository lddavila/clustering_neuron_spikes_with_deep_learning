function nearsim_spikes = find_nearsim_spikes_ver_2(spikes, tvals)
%FIND_NEARSIM_SPIKES Finds spike windows which are likely to contain more
%than one spike (i.e., there is a presence of multiple spike waveforms).
%   nearsim_spikes = FIND_NEARSIM_SPIKES(spikes, tvals)
%
%   'spikes' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%
%   'tvals' are the threshold values for each wire in microvolts.
%
%   'nearsim_spikes' is a logical index array for which spike windows have
%   multiple, nearly simultaneous spikes.
    
    [numwires, numspikes, numdp] = size(spikes);
    p_spikes = permute(spikes, [3 1 2]);
    nearsim_spikes = false(1, numspikes);
    mindist = ceil(0.33 * numdp); % 200 Microseconds, min distance between the peaks of two spikes
    
    % mindist = 6; % 200 Microseconds, min distance between the peaks of two spikes
    
    pks = cell(numwires, numspikes);
    
    % Find peaks and valleys for all spikes (local min/max)
    for w = 1:numwires
        wire = squeeze(spikes(w, :, :));
        pks(w, :) = find_peaks(wire, true);
    end
    % plot_the_peaks(pks)
    for s = 1:numspikes
        spike = p_spikes(:, :, s); %all data points in spike s, across all channels in the tetrode 
        
        poss_peaks = cell(1, numwires); %
        min_pk = NaN;
        max_pk = NaN;
        for w = 1:numwires % for each channel in the spike 
            x = spike(:, w); % all spike dps for spike s, for only channel w
            peak_idx = pks{w, s}; %a array with the indexes of the spike which are part of the peak
            
            poss_peaks_idx = peak_idx(x(peak_idx) >= 1.25*tvals(w) & x(peak_idx) >= 0.25 * max(x));
            %Check which of the peak dps are greater than or equal to 1.25*tvals for wire w
            %and also greater than or equal to 0.25 * max value in the entire spike (not just the peak)
            if ~isempty(poss_peaks_idx)
                min_pk = min(min_pk, min(poss_peaks_idx));
                max_pk = max(max_pk, max(poss_peaks_idx));
            end
            poss_peaks{w} = poss_peaks_idx;
        end
        if max_pk - min_pk >= mindist
            nearsim_spikes(s) = true;
        end
    end
end