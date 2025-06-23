function [output, aligned, reg_timestamps] = run_spikesort_ntt_core(raw, timestamps, good_spikes_idx_inj, ir, tvals, filenames, config)
%RUN_SPIKESORT_NTT_CORE Runs spike sorter on data extracted from the
%tetrode.
%   [output, aligned, reg_timestamps] = RUN_SPIKESORT_NTT_CORE(raw,
%   timestamps, good_spikes_idx_inj, ir, tvals, filenames)
%
%   'raw' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%   It represents the raw spike samples recorded.
%
%   'timestamps' are the timestamps for each spike in microseconds.
%
%   'good_spikes_idx_inj' is the set of indices for not obviously noisy
%   spikes (acts as an injection function).
%
%   'ir' are the input range values for each wire in microvolts.
%
%   'tvals' are the threshold values for each wire in microvolts.
%
%   'filenames' is a structure of all of the useful filenames for saving.
%
%   'config' is the global spikesort configuration struct.
%
%   'output' is the resulting output matrix, containing timestamps and
%   cluster classification.
%
%   'aligned' is an array of the aligned spikes (similar to 'raw'), which
%   only contains spikes that are not "nearly simultaneous"
%
%   'reg_timestamps' are the timestamps for each spike that is not "nearly
%   simultaneous"

    interp_raw = interpolate_spikes(raw, config);
    % Fix interpolated spikes that hit threshhold
%     for w = 1:size(interp_raw, 1)
%         interp_raw(w, ir(w) - interp_raw(w, :, :) < ir(w) * 0.03) = ir(w);
%     end

    good_interp_raw = interp_raw(:, good_spikes_idx_inj, :);
    if config.NEAR_SIMULTANEOUS_SPIKE_DETECTION
        nearsim_spikes = find_nearsim_spikes(good_interp_raw, tvals);

        reg_spikes_idx = good_spikes_idx_inj(~nearsim_spikes);
        reg_interp_raw = interp_raw(:, reg_spikes_idx, :);
        reg_timestamps = timestamps(reg_spikes_idx);
    else
        reg_interp_raw = good_interp_raw;
        reg_timestamps = timestamps(good_spikes_idx_inj);
    end
    
    % Run the spikesort algorithm (with only the spike-sort related config
    % struct).
    [aligned, cf, grades] = spikesort(reg_interp_raw, reg_timestamps, ir, tvals, config.spikesort);

    if config.ALIGN_OUTPUT
        reg_aligned = align_to_peak(reg_interp_raw, tvals, ir);
        num_sample_points = size(raw, 3);
        reg_raw = downsample_spikes(reg_aligned, num_sample_points, ir, config);
    else
        reg_raw = raw(:, reg_spikes_idx, :);
    end
    reg_output = af2mat(cf, reg_raw, reg_timestamps, config.save_waveforms);

    if config.NEAR_SIMULTANEOUS_SPIKE_DETECTION
        nearsim_spikes_idx = good_spikes_idx_inj(nearsim_spikes);
        nearsim_interp_raw = interp_raw(:, nearsim_spikes_idx, :);
        nearsim_timestamps = timestamps(nearsim_spikes_idx);

        [extracted_spikes, ex_ts] = extract_spikes(nearsim_interp_raw, nearsim_timestamps, tvals);
        if isempty(ex_ts)
            output = reg_output;
        else
            clust_idx = classify_nearsim_spikes(reg_raw, cf, extracted_spikes, config.spikesort);
            if config.ALIGN_OUTPUT
                interp_nearsim_spikes = align_to_peak(extracted_spikes, tvals, ir);
            else
                interp_nearsim_spikes = extracted_spikes;
            end
            num_sample_points = size(raw, 3);
            downsampled = downsample_spikes(interp_nearsim_spikes, num_sample_points, ir, config);

            multispike_output = af2mat(clust_idx, downsampled, ex_ts, config.save_waveforms);
            output = sortrows([reg_output ; multispike_output]);
        end
    else
        output = reg_output;
    end

    if config.SAVE_NTT
        mk_dg_cutClust2Nlx(output, filenames.ntt, ir, tvals);
        if config.SAVE_WAVEFORMS
            save_output(filenames.output, output);
        else
            reg_output = af2mat(cf, reg_raw, reg_timestamps, false);
            if ~config.NEAR_SIMULTANEOUS_SPIKE_DETECTION || isempty(ex_ts)
                output = reg_output;
            else
                multispike_output = af2mat(clust_idx, downsampled, ex_ts, false);
                output = sortrows([reg_output ; multispike_output]);
            end
            save_output(filenames.output, output);
        end
    end
    
    means = cellmap(@(x) squeeze(mean(aligned(:, x, :), 2)), cf);
    [final_grades, confidence] = compute_final_grades(grades, config.spikesort);
    
    save_info(filenames.info, grades, final_grades, confidence, means, filenames.orig);
end