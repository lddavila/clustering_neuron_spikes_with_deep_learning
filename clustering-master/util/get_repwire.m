%edited by Luis David Davila and Alexander Friedman
function the_repwire = get_repwire(the_raw, the_tvals, the_ir)
%GET_REPWIRE Gets the representative recording of each spike
    numwires = size(the_raw, 1);
    numspikes = size(the_raw, 2);
    numdp = size(the_raw, 3);
    [peaks, pks_idx] = max(the_raw, [], 3);
    maxvals = repmat(the_ir, 1, numspikes) - 0.1;
    peaks(peaks >= maxvals) = -inf;
    
    [~, ind] = sort(peaks, 'descend');
    
    max_pos_spike_dist = round(0.05 * numdp); % 50 microseconds
    
%     for s = 1:numspikes
%         spike = squeeze(raw(:, s, :));
%         
%     end
    
    the_repwire = nan(numspikes, numdp);
    for wire = 1:numwires
        vals = find(ind(1, :) == wire);
        r = squeeze(the_raw(wire, vals, :));
        valleys_idx = find_peaks(r * (-1));
        for s = 1:length(vals)
            val = vals(s);
            valley_idx = valleys_idx{s};
            first_valley_before = valley_idx(find(valley_idx < pks_idx(wire, val), 1, 'last'));
            if ~isempty(first_valley_before)
                for w2 = 2:size(ind, 1)
                    wire2 = ind(w2, val);
                    if peaks(wire2, val) >= the_tvals(wire2) - 0.1 && ...
                            abs(pks_idx(wire2, val) - first_valley_before) <= max_pos_spike_dist
                        r(s, :) = squeeze(the_raw(ind(w2, val), val, :));
                        break
                    end
                end
            end
        end
        the_repwire(vals, :) = r;
    end
end
