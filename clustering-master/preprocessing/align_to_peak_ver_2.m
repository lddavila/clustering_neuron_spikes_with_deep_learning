function aligned = align_to_peak_ver_2(spikes, tvals, ir)
%ALIGN_TO_PEAK Aligns spikes so that the peak for all spikes is in the same
%index.
%   aligned = ALIGN_TO_PEAK(spikes, tvals, ir)
%
%   'spikes' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%
%   'tvals' are the threshold values for each wire in microvolts.
%
%   'ir' are the input range values for each wire in microvolts.
%
%   'aligned' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%   It is the same as 'raw', but with spikes aligned to have the same peak
%   index.

    [numwires, numspikes, numdp] = size(spikes);
%     rep = get_repwire(spikes, tvals, ir);
    
    align_peak = round(numdp * 0.2); % 200 microsecond mark (ORIGINAL LINE)
    % align_peak = 6; % 200 microsecond mark
    numaligneddp = round(numdp*1.25);
    aligned = zeros(numwires, numspikes, numaligneddp);
    
    p_spikes = permute(spikes, [3 1 2]);
    %p_spike is now ordered #dps, #channels, #spikes
    
    new_align_peak = round(0.75 * (numaligneddp - numdp)) + align_peak;
    for w = 1:numwires
        for s = 1:numspikes
            pk_range = round(1/6 * numdp) : round(5/6 * numdp);
            [~, max_pk_idx] = max(p_spikes(pk_range, w, s));
            
            pk_idx = pk_range(max_pk_idx);
                
            aligned_delta = new_align_peak - pk_idx;
            range = (1:numdp) + aligned_delta;
            n_range = range(1 <= range & range <= numaligneddp);
            if pk_idx <= -aligned_delta
                disp('hmm')
            end
            if range(1) < 1
                al_spike = p_spikes(end-length(n_range)+1:end, w, s);
            elseif range(end) > numaligneddp
                al_spike = p_spikes(1:length(n_range), w, s);
            else
                al_spike = p_spikes(:, w, s);
            end
            aligned(w, s, n_range) = al_spike;
        end
    end
end