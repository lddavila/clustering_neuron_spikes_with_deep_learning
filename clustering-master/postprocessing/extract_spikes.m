function [extracted_spikes, new_timestamps] = extract_spikes(spikes, timestamps, tvals)
%EXTRACT_SPIKES Extracts spikes from a single recording window.
%   [extracted_spikes, new_timestamps] = EXTRACT_SPIKES(spikes, timestamps,
%   tvals)
%
%   'spikes' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%
%   'timestamps' are the timestamps for each spike in microseconds.
%
%   'tvals' are the threshold values for each wire in microvolts.
%
%   'extracted_spikes' are the extracted spikes, which have the same length
%   as the original spikes because they are padded on both sides.
%
%   'new_timestamps' are the recalculated timestamps of the extracted
%   spikes to more accurately distinguish the multiple spikes in the
%   window.

    [numwires, numspikes, numdp] = size(spikes);
    p_spikes = permute(spikes, [3 1 2]);
    
    mindist = ceil(0.25 * numdp); % 250 Microseconds, min distance between the peaks of two spikes
    
    pks = cell(numwires, numspikes);
    vals = pks;
    
    % Find peaks and valleys for all spikes (local min/max)
    for w = 1:numwires
        wire = shiftdim(spikes(w, :, :), 1);
        pks(w, :) = find_peaks(wire);
        vals(w, :) = find_peaks(wire * (-1));
    end
    
    % Process each spike
    extended_len = numdp;
    spike_buffer = 2*numspikes;
    extracted_spikes = zeros(numwires, spike_buffer, extended_len);
    new_timestamps = nan(1, spike_buffer);
    cur_spike = 1;
    for s = 1:numspikes
        spike = p_spikes(:, :, s);
        
        actual_peaks = cell(1, numwires);
        all_actual_peaks_idx = false(1, numdp);
        
        % For each wire, get the peaks of real spikes
        for w = 1:numwires
            x = spike(:, w);
            peak_idx = pks{w, s};
            vals_idx = vals{w, s};
            
            poss_peaks = peak_idx(x(peak_idx) >= 0.99 * tvals(w));
            [~, ind] = max(spike(poss_peaks, :), [], 2);
            test_peaks = poss_peaks(ind == w);
            
            % Look for peaks that have a valley below 1/2 threshold before
            % the next peak above threshold
            keep_peaks = [];
            for k = 1:length(test_peaks)
                p1 = test_peaks(k);
                p2 = poss_peaks(find(p1 < poss_peaks, 1, 'first'));
                if isempty(p2)
                    p2 = numdp;
                end
                low_valley = find(p1 < vals_idx & vals_idx < p2 & x(vals_idx) < tvals(w)/2, 1);
                if ~isempty(low_valley)
                    keep_peaks(end+1) = p1;
                end
            end
            if ~isempty(keep_peaks)
                actual_peaks{w} = keep_peaks;
                all_actual_peaks_idx(keep_peaks) = true;
            end
        end
        
        all_actual_peaks = find(all_actual_peaks_idx);
        
        % Keep only peaks that are more than 250 ms apart (otherwise the
        % spikes are too close to not be corrupted anyway)
        for w1 = 1:numwires
            x1 = spike(:, w1);
            peaks1 = actual_peaks{w1};
            for w2 = w1+1:numwires
                x2 = spike(:, w2);
                peaks2 = actual_peaks{w2};
                for k1 = 1:length(peaks1)
                    p1 = peaks1(k1);
                    for k2 = 1:length(peaks2)
                        p2 = peaks2(k2);
                        if abs(p1 - p2) <= mindist
                            if x1(p1) > x2(p2)
                                remove_idx = p2;
                                actual_peaks{w2} = simple_setdiff(actual_peaks{w2}, p2);
                            else
                                remove_idx = p1;
                                actual_peaks{w1} = simple_setdiff(actual_peaks{w1}, p1);
                            end
                            all_actual_peaks = simple_setdiff(all_actual_peaks, remove_idx);
                        end
                    end
                end
            end
        end
        
        % Finally go through each peak remaining and figure out where to
        % cut the spike. If there are no spikes before, use the peak
        % before. Otherwise the first valley to the left. If there are no
        % spikes after, use the peak after. Otherwise the first valley to
        % the right.
%         cut_spike(s, spike, actual_peaks, all_actual_peaks);
        for ww = 1:numwires
            peaks = actual_peaks{ww};
            if isempty(peaks)
                continue
            end
            pks_idx = pks{ww, s};
            valley_idx = vals{ww, s};
            corrupted = false;
            for q = 1:length(peaks)
                pk_idx = peaks(q);
                actual_pk_idx = find(all_actual_peaks == pk_idx);
                if actual_pk_idx == 1
                    prev_pk_idx = pks_idx(find(pks_idx < pk_idx, 1, 'last'));
                    if isempty(prev_pk_idx)
                        lower = 1;
                    else
                        lower = prev_pk_idx;
                    end
                else
                    prev_actual_peak = all_actual_peaks(actual_pk_idx - 1);
                    val_idx = valley_idx(find(prev_actual_peak < valley_idx & valley_idx < pk_idx, 1, 'last'));
                    if isempty(val_idx)
                        % Corrupted spike
                        corrupted = true;
                        break
                    else
                        lower = val_idx;
                    end
                end
                if actual_pk_idx == length(all_actual_peaks)
                    next_pk_idx = pks_idx(find(pks_idx > pk_idx, 1, 'first'));
                    if isempty(next_pk_idx)
                        upper = numdp;
                    else
                        upper = next_pk_idx;
                    end
                else
                    next_actual_peak = all_actual_peaks(actual_pk_idx + 1);
                    val_idx = valley_idx(find(pk_idx < valley_idx & valley_idx < next_actual_peak, 1, 'last'));
                    if isempty(val_idx)
                        % Corrupted spike
                        corrupted = true;
                        break
                    else
                        upper = val_idx;
                    end
                end
                
                spike_pks = spike(pk_idx, :);
                if any(spike(lower, :) > spike_pks)
                    inds = lower+1:pk_idx-1;
                    r_spike_pks = repmat(spike_pks, length(inds), 1);
                    lower = inds(find(all(spike(inds, :) <= r_spike_pks, 2), 1, 'first'));
                end
                if any(spike(upper, :) > spike_pks)
                    inds = pk_idx+1:upper-1;
                    r_spike_pks = repmat(spike_pks, length(inds), 1);
                    upper = inds(find(all(spike(inds, :) <= r_spike_pks, 2), 1, 'last'));
                end
                
                if isempty(lower) || isempty(upper)
                    continue
                end
                
                spike_range = lower:upper;
                spike_len = upper - lower + 1;
                insert_lower = floor((extended_len - spike_len)/2) + 1;
                insert_idx = insert_lower : insert_lower + spike_len - 1;
                % TODO: Offset the other wires by the same offset as the
                % peak instead of just using spike_range for all wires
                extracted_spike = spike(spike_range, :);
                extracted_spikes(:, cur_spike, insert_idx) = extracted_spike';
                new_timestamps(cur_spike) = timestamps(s) + (lower - 1)*1e3/numdp;
                cur_spike = cur_spike + 1;
            end
            if corrupted
                break
            end
        end
    end
    extra_range = cur_spike:spike_buffer;
    extracted_spikes(:, extra_range, :) = [];
    new_timestamps(extra_range) = [];
end