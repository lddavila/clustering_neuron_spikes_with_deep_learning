function [output, aligned, reg_timestamps,reg_timestamps_of_the_spikes,peak_pcs,cleaned_clusters] = run_spikesort_ntt_core_ver4(timestamps, good_spikes_idx_inj, ir, tvals, filenames, config,channels,sorted_spike_windows,interp_raw,varargin)
%OG: [output, aligned, reg_timestamps,reg_timestamps_of_the_spikes]
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
% disp("Got inside of run_spikesort_ntt_core_ver4.m")
% interp_raw = interpolate_spikes(raw, config);
% disp("Finished interpolating spikes")
% Fix interpolated spikes that hit threshhold
%     for w = 1:size(interp_raw, 1)
%         interp_raw(w, ir(w) - interp_raw(w, :, :) < ir(w) * 0.03) = ir(w);
%     end






good_interp_raw = interp_raw(:, good_spikes_idx_inj, :);

filter_2 = good_spikes_idx_inj;
if ~isempty(varargin)
    modded_base_aligned_idxs = varargin{1};
    modded_base_aligned_idxs = modded_base_aligned_idxs(filter_2);
end

config.mutated_spike_windows = config.mutated_spike_windows(good_spikes_idx_inj,:);

if config.debug_with_ground_truth && config.has_ground_truth
    % config = check_unit_detection_while_clustering(config.mutated_spike_windows,current_tetrode,config,"aftergoodspikesidxinjmult"+string(config.which_thresh),interp_raw,good_spikes_idx_inj);
    config.plot_counter = config.plot_counter + 1;
    config = check_snr_of_spike_windows_with_table(config,config.mutated_spike_windows);
    config.stage_counter = config.stage_counter + 1;
end
% disp("Finished getting unit decetion while clustering 1")
if config.NEAR_SIMULTANEOUS_SPIKE_DETECTION
    nearsim_spikes = find_nearsim_spikes_ver_2(good_interp_raw, tvals);

    reg_spikes_idx = good_spikes_idx_inj(~nearsim_spikes);
    reg_interp_raw = interp_raw(:, reg_spikes_idx, :);
    reg_timestamps = timestamps(reg_spikes_idx);
    reg_timestamps_of_the_spikes = timestamps(reg_spikes_idx,31);
    reg_sorted_spike_windows = sorted_spike_windows(reg_spikes_idx,:);
    filter_3 = reg_spikes_idx;
    % save(fullfile(dir_to_save_spike_windows_to,current_tetrode+" sorted_spike_windows_after_purges.mat"),"reg_sorted_spike_windows");
else
    reg_interp_raw = good_interp_raw;
    reg_timestamps = timestamps(good_spikes_idx_inj);
    reg_timestamps_of_the_spikes = timestamps(good_spikes_idx_inj,31);
    reg_sorted_spike_windows = sorted_spike_windows(good_spikes_idx_inj,:);
    filter_3= good_spikes_idx_inj;
    
    % save(fullfile(dir_to_save_spike_windows_to,current_tetrode+" sorted_spike_windows_after_purges.mat"),"reg_sorted_spike_windows");
end

%TEST REMOVAL
% if ~isfile(config.base_aligned_name)
%     base_aligned = align_to_peak_ver_2(reg_interp_raw,tvals,ir);
%     par_save(config.base_aligned_name,base_aligned);
%     base_aligned_idxs = 1:1:size(base_aligned,2);
%     par_save(config.base_aligned_sw_name,reg_sorted_spike_windows)
% else
%     base_aligned_idxs = varargin{1};
% end
%TEST REMOVAL END


if ~isempty(varargin)
    modded_base_aligned_idxs = modded_base_aligned_idxs(filter_3);
end

%check how detection is affected at the current if set on the config
config.mutated_spike_windows = config.mutated_spike_windows(reg_spikes_idx,:);
if config.debug_with_ground_truth && config.has_ground_truth
    % config = check_unit_detection_while_clustering(reg_sorted_spike_windows,current_tetrode,config,"afternearsimspikedetfiltmult"+string(config.which_thresh),reg_interp_raw,1:size(reg_interp_raw,2));
    config.plot_counter = config.plot_counter+1;
    config = check_snr_of_spike_windows_with_table(config,reg_sorted_spike_windows);
    config.stage_counter = config.stage_counter+1;
    % disp("Finished getting unit decetion while clustering 2")
end

% PERFECTLY ALIGNED UP TO THIS POINT
%do an uncomment on everything below this line, do not include this line
% Run the spikesort algorithm (with only the spike-sort related config
% struct).
if isempty(varargin)
    [aligned, cf, timestamps_1,r_tvals,peak_pcs] = spikesort_ver_4(reg_interp_raw, reg_timestamps, ir, tvals, config.spikesort,channels,config.peak_pcs_file_name,config);
else
    [aligned, cf, timestamps_1,r_tvals,peak_pcs] = spikesort_ver_4(reg_interp_raw, reg_timestamps, ir, tvals, config.spikesort,channels,config.peak_pcs_file_name,config,modded_base_aligned_idxs);
end



% plot_the_cf(cf,aligned,"Called by run_spikesort_ntt_core_ver2");

%%%%%%%%%_______________COMMENTED OUT BECAUSE OUTPUT IS IRRELEVANT TO US AT THIS POINT
% if config.ALIGN_OUTPUT && size(reg_interp_raw,2)~=0
%     reg_aligned = align_to_peak(reg_interp_raw, tvals, ir);
%     num_sample_points = size(raw, 3);
%     reg_raw = downsample_spikes(reg_aligned, num_sample_points, ir, config);
% else
%     reg_raw = raw(:, reg_spikes_idx, :);
% end
% reg_output = af2mat(cf, reg_raw, reg_timestamps, config.save_waveforms);
% 
% if config.NEAR_SIMULTANEOUS_SPIKE_DETECTION
%     nearsim_spikes_idx = good_spikes_idx_inj(nearsim_spikes);
%     nearsim_interp_raw = interp_raw(:, nearsim_spikes_idx, :);
%     nearsim_timestamps = timestamps(nearsim_spikes_idx);
% 
%     [extracted_spikes, ex_ts] = extract_spikes(nearsim_interp_raw, nearsim_timestamps, tvals);
%     if isempty(ex_ts)
%         output = reg_output;
%     else
%         clust_idx = classify_nearsim_spikes(reg_raw, cf, extracted_spikes, config.spikesort);
%         if config.ALIGN_OUTPUT
%             interp_nearsim_spikes = align_to_peak(extracted_spikes, tvals, ir);
%         else
%             interp_nearsim_spikes = extracted_spikes;
%         end
%         num_sample_points = size(raw, 3);
%         downsampled = downsample_spikes(interp_nearsim_spikes, num_sample_points, ir, config);
% 
%         multispike_output = af2mat(clust_idx, downsampled, ex_ts, config.save_waveforms);
%         output = sortrows([reg_output ; multispike_output]);
%     end
% else
%     output = reg_output;
% end
% 
% if ~config.SAVE_NTT
%     mk_dg_cutClust2Nlx(output, filenames.ntt, ir, tvals);
%     if config.SAVE_WAVEFORMS
%         save_output(filenames.output, output);
%     else
%         reg_output = af2mat(cf, reg_raw, reg_timestamps, false);
%         if ~config.NEAR_SIMULTANEOUS_SPIKE_DETECTION || isempty(ex_ts)
%             output = reg_output;
%         else
%             multispike_output = af2mat(clust_idx, downsampled, ex_ts, false);
%             output = sortrows([reg_output ; multispike_output]);
%         end
%         save_output(filenames.output, output);
%     end
% end
%%%%%%%%%_______________COMMENTED OUT BECAUSE OUTPUT IS IRRELEVANT TO US AT THIS POINT

cleaned_clusters = cf;
output = [];

save_info_ver_2(filenames, filenames,timestamps_1,r_tvals,cleaned_clusters);
end