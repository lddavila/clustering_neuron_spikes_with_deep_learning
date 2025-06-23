function peaks = get_peaks(spikes, is_aligned, tvals, ir)
    if nargin == 1
        peaks = max(spikes, [], 3);
    elseif nargin >= 2
        [numwires, numspikes, numdp] = size(spikes);
        if is_aligned
            [~, peaks_idx] = max(spikes, [], 3);
            peaks = nan(numwires, numspikes);
            for w = 1:numwires
                pk_idx = mode(peaks_idx(w, :));
                peaks(w, :) = spikes(w, :, pk_idx);
            end
        elseif nargin == 4
            rep = get_repwire(spikes, tvals, ir);
            [~, peaks_idx] = max(rep, [], 2);

            p_spikes = permute(spikes, [3 1 2]);
            dist = round(0.25 * numdp);
            
            peaks = nan(numwires, numspikes);

            for w = 1:numwires
                for s = 1:numspikes
                    pk_range = max(1, peaks_idx(s) - dist) : min(numdp, peaks_idx(s) + dist);
                    [~, pk_idx] = max(p_spikes(pk_range, w, s));
                    peaks(w, s) = p_spikes(pk_range(pk_idx), w, s);
                end
            end
        end
    end
end