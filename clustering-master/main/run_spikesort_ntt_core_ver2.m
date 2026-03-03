%updated by Luis David Davila and Alexander Friedman
function [the_output, the_aligned, the_reg_timestamps] = run_spikesort_ntt_core_ver2(the_raw, the_timestamps, the_good_spikes_idx_inj, the_ir, the_tvals, the_filenames, the_config,the_channels,the_iteration_number)
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
    
    % plot_the_spikes(raw,"Beginning",1,channels)
    % plot_the_spikes_ver_2(raw,"Beginning",1,channels,timestamps)
    interp_raw = interpolate_spikes(the_raw, the_config);
    % Fix interpolated spikes that hit threshhold
%     for w = 1:size(interp_raw, 1)
%         interp_raw(w, ir(w) - interp_raw(w, :, :) < ir(w) * 0.03) = ir(w);
%     end

    good_interp_raw = interp_raw(:, the_good_spikes_idx_inj, :);
    if the_config.NEAR_SIMULTANEOUS_SPIKE_DETECTION
        nearsim_spikes = find_nearsim_spikes_ver_2(good_interp_raw, the_tvals);

        reg_spikes_idx = the_good_spikes_idx_inj(~nearsim_spikes);
        reg_interp_raw = interp_raw(:, reg_spikes_idx, :);
        the_reg_timestamps = the_timestamps(reg_spikes_idx);
    else
        reg_interp_raw = good_interp_raw;
        the_reg_timestamps = the_timestamps(the_good_spikes_idx_inj);
    end
    
    % Run the spikesort algorithm (with only the spike-sort related config
    % struct).
    [the_aligned, cf, grades] = spikesort_ver_2(reg_interp_raw, the_reg_timestamps, the_ir, the_tvals, the_config.spikesort,the_channels);
    %plot_the_spikes_ver_2(raw,"Before Alignment",[4],channels,timestamps);
    %plot_the_spikes_ver_3(aligned,"After Alignment",[4],channels);
    % plot_the_spikes_ver_4(raw,"Before Alignment Channel 1",1)
    % plot_the_spikes_ver_4(aligned,"After Alignment Channel 1",1)
    % plot_the_spikes(aligned,"Aligned",1,channels);

    % plot_the_cf(cf,aligned,"Called by run_spikesort_ntt_core_ver2");
    if the_config.ALIGN_OUTPUT
        reg_aligned = align_to_peak(reg_interp_raw, the_tvals, the_ir);
        num_sample_points = size(the_raw, 3);
        reg_raw = downsample_spikes(reg_aligned, num_sample_points, the_ir, the_config);
    else
        reg_raw = the_raw(:, reg_spikes_idx, :);
    end
    reg_output = af2mat(cf, reg_raw, the_reg_timestamps, the_config.save_waveforms);

    if the_config.NEAR_SIMULTANEOUS_SPIKE_DETECTION
        nearsim_spikes_idx = the_good_spikes_idx_inj(nearsim_spikes);
        nearsim_interp_raw = interp_raw(:, nearsim_spikes_idx, :);
        nearsim_timestamps = the_timestamps(nearsim_spikes_idx);

        [extracted_spikes, ex_ts] = extract_spikes(nearsim_interp_raw, nearsim_timestamps, the_tvals);
        if isempty(ex_ts)
            the_output = reg_output;
        else
            clust_idx = classify_nearsim_spikes(reg_raw, cf, extracted_spikes, the_config.spikesort);
            if the_config.ALIGN_OUTPUT
                interp_nearsim_spikes = align_to_peak(extracted_spikes, the_tvals, the_ir);
            else
                interp_nearsim_spikes = extracted_spikes;
            end
            num_sample_points = size(the_raw, 3);
            downsampled = downsample_spikes(interp_nearsim_spikes, num_sample_points, the_ir, the_config);

            multispike_output = af2mat(clust_idx, downsampled, ex_ts, the_config.save_waveforms);
            the_output = sortrows([reg_output ; multispike_output]);
        end
    else
        the_output = reg_output;
    end

    if ~the_config.SAVE_NTT
        mk_dg_cutClust2Nlx(the_output, the_filenames.ntt, the_ir, the_tvals);
        if the_config.SAVE_WAVEFORMS
            save_output(the_filenames.output, the_output);
        else
            reg_output = af2mat(cf, reg_raw, the_reg_timestamps, false);
            if ~the_config.NEAR_SIMULTANEOUS_SPIKE_DETECTION || isempty(ex_ts)
                the_output = reg_output;
            else
                multispike_output = af2mat(clust_idx, downsampled, ex_ts, false);
                the_output = sortrows([reg_output ; multispike_output]);
            end
            save_output(the_filenames.output, the_output);
        end
    end
    
    means = cellmap(@(x) squeeze(mean(the_aligned(:, x, :), 2)), cf);
    [final_grades, confidence] = compute_final_grades(grades, the_config.spikesort);
    
    save_info(the_filenames(the_iteration_number),grades,final_grades,confidence,means,the_filenames(the_iteration_number));
end