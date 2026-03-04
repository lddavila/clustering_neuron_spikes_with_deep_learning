%edited by Luis David Davila and Alexander Friedman
function the_peaks = get_peaks(the_spikes, the_is_aligned, the_tvals, the_ir)
    if nargin == 1
        the_peaks = max(the_spikes, [], 3);
    elseif nargin >= 2
        [numwires, numspikes, numdp] = size(the_spikes);
        if the_is_aligned
            [~, peaks_idx] = max(the_spikes, [], 3);
            the_peaks = nan(numwires, numspikes);
            for w = 1:numwires
                pk_idx = mode(peaks_idx(w, :));
                the_peaks(w, :) = the_spikes(w, :, pk_idx);
            end
        elseif nargin == 4
            rep = get_repwire(the_spikes, the_tvals, the_ir);
            [~, peaks_idx] = max(rep, [], 2);

            p_spikes = permute(the_spikes, [3 1 2]);
            dist = round(0.25 * numdp);
            
            the_peaks = nan(numwires, numspikes);

            for w = 1:numwires
                for s = 1:numspikes
                    pk_range = max(1, peaks_idx(s) - dist) : min(numdp, peaks_idx(s) + dist);
                    [~, pk_idx] = max(p_spikes(pk_range, w, s));
                    the_peaks(w, s) = p_spikes(pk_range(pk_idx), w, s);
                end
            end
        end
    end
end