function [raw, timestamps, good_spike_idx, inputrange, threshvals, errmsg] = extract_raw(ntt_file, config)
%EXTRACT_RAW Extracts information from an NTT file.
%   [raw, timestamps, good_spike_idx, inputrange, threshvals, errmsg] =
%   EXTRACT_RAW(ntt_file, config)
%
%   'ntt_file' is the filename of the NTT file to extract.
%
%   'config' is the spikesort configuration struct.
%
%   'raw' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%   It represents the raw spike samples recorded.
%
%   'timestamps' are the timestamps for each spike in microseconds.
%
%   'good_spike_idx' are the indices for spikes which pass the most basic
%   checks against noise.
%
%   'inputrange' are the input range values for each wire in microvolts.
%
%   'threshvals' are the threshold values for each wire in microvolts.
%
%   See also RUN_SPIKESORT_NTT_CORE, RUN_SPIKESORT_NTT, RUN_SPIKESORT.

    % Initialized return variables in case we need to return early.
    raw = [];
    timestamps = [];
    good_spike_idx = [];
    admax_val = NaN;
    adbit_vals = [];
    inputrange = [];
    threshvals = [];
    errmsg = '';
    
    try
        [timestamps, samples, header] = dg_readSpike(ntt_file);
    catch
        errmsg = 'Error reading NTT file.';
        return
    end
    
    % Clean up samples and timestamps in case there are timestamps of '0'
    samples(:, :, timestamps == 0) = [];
    timestamps(timestamps == 0) = [];
    
    if isempty(samples)
        errmsg = 'Empty tetrode.';
        return
    end
    
    is_high_firing_rate = size(samples, 3) / (timestamps(end) - timestamps(1)) * 1e6 > config.MAX_FIRING_RATE;
    is_too_many_spikes = size(samples, 3) > config.MAX_NUM_SPIKES;
    
    if is_high_firing_rate || is_too_many_spikes
        % Probably horrible data.
        timestamps = [];
        errmsg = 'Firing rate too high or too many spikes.';
        return
    end
    
    % Get information from the header
    for k = 1:length(header)
        line = header{k};
        if strfind(line, 'ADMaxValue')
            admax_val = textscan(line(13:end), '%d');
            admax_val = admax_val{1};
        elseif strfind(line, 'ADBitVolts')
            adbit_vals = textscan(line(13:end), '%f');
            adbit_vals = adbit_vals{1}';
        elseif strfind(line, 'InputRange')
            inputrange = textscan(line(13:end), '%d');
            inputrange = double(inputrange{1});
        elseif strfind(line, 'ThreshVal')
            threshvals = textscan(line(12:end), '%d');
            threshvals = double(threshvals{1});
            break
        end
    end
    if isnan(admax_val) || isempty(adbit_vals) || isempty(threshvals)
        warning('extract_raw:incomplete_header', 'Incomplete tetrode header')
        if isnan(admax_val)
            admax_val = 32767;
        end
        if isempty(adbit_vals)
            if ~isempty(inputrange)
                adbit_vals = inputrange' / 1e6 / admax_val;
            else
                adbit_vals = repmat(6e-9, 1, size(samples, 2));
            end
        end
    end
    
    % Converts bit values to microvolts and permutes the array into a
    % convenient format
    numspikes = size(samples, 3);
    dp_volts = samples .* repmat(adbit_vals, [32 1 numspikes]);
    dp_mv = dp_volts * 1e6; % Microvolts
    raw = permute(dp_mv, [2 3 1]);
    
    if isempty(threshvals)
        [~, repind] = max(max(raw, [], 3), [], 1);
        threshvals = nan(size(raw, 1), 1);
        for w = 1:size(raw, 1)
            threshvals(w) = min(max(raw(w, repind==w, :), [], 3));
        end
    end
    if isempty(inputrange)
        inputrange = adbit_vals' * double(admax_val) * 1e6;
    end
    
    % Find samples in which all four wires reach admax_val
    wire_filter = find_live_wires(raw);
    nonzero_samples = samples(:, wire_filter, :);
    
    minpeaks = shiftdim(min(max(nonzero_samples), [], 2), 2);
    maxvals = shiftdim(max(min(nonzero_samples), [], 2), 2);
    
    good_spike_filter = minpeaks < admax_val & maxvals > (-admax_val);
    if sum(good_spike_filter) < config.MIN_NUMBER_OF_SPIKES
        errmsg = sprintf('Fewer than %d good spikes', config.MIN_NUMBER_OF_SPIKES);
        return
    end
    
    good_spike_idx = find(good_spike_filter);
end