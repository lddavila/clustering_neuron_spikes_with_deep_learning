%edited by Luis David Davila and Alexander Friedman
function [the_good_filt,the_cfs] = remove_bad_clusters(the_aligned, the_cfs, the_ir, the_tvals, the_config,full_config,varargin)
%REMOVE_BAD_CLUSTERS Removes obviously bad clusters before they can do any
%harm!
%   good_filt = REMOVE_BAD_CLUSTERS(aligned, cfs)
%
%   'aligned' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%   It is the same as 'raw', but with spikes aligned to have the same peak
%   index.
%
%   'cfs' is a cell array of indices for each cluster.
%
%   'good_filt' is a logical index array for which clusters are good
%   (not terrible).

% TODO: special behavior for clusters far from tvals.

    the_good_filt = true(1, length(the_cfs));
    all_peaks = get_peaks(the_aligned, true)';

    %by default any clusters with size less than 100 will be considered a
    %bad cluster
    cf_sizes = cellfun(@length,the_cfs);
    the_good_filt(cf_sizes<1000) = false;

    
    for k = 1:length(the_cfs)
        cf = the_cfs{k};
        if ~the_good_filt(k)
            continue;
        end
        peaks = all_peaks(cf, :);
        if the_config.params.RB_TRUST_SMALL_ISOLATED && length(cf) < 1000
            non_cluster_idx = setdiff(1:size(all_peaks, 1), cf);
            bdist = bhat_dist(peaks, all_peaks(non_cluster_idx, :));
            if bdist > 2
                % Small cluster far from everything else, so better to not
                % remove it and instead assume it's ok.
                continue
            end
        end
        
        mean_peaks = mean(peaks);
        far_thresh = the_config.TRUST_FAR_NEURONS && any(mean_peaks > ((3 * the_tvals' & mean_peaks )./ the_ir') > 0.6);
        if far_thresh
            % Very distant cluster from thresh - do not attempt bad cluster removal
            continue
        end
        num_peaks = size(peaks, 2);
        [~, peakpcs] = pca(peaks);
        data = zscore([peaks, peakpcs(:, 1:num_peaks-1)]);
        data = zscore(peaks); % edited by luis david davila on 05/06/2026

        if isempty(varargin)
            dim_filter = select_dimensions_dip(data, the_config);
        else
            [dim_filter,~,the_fig_handle]= select_dimensions_dip(data,the_config,varargin{1});
        end
        if all(dim_filter) %if they are all bad then we say it's a bad cluster & move on
            the_good_filt(k) = false;
            continue;
        end

        disp("Cluster "+string(k)+"_"+sprintf('%i',dim_filter));
        current_channels = full_config.current_channels;
        good_channels = current_channels(~dim_filter);
        spike_windows = full_config.mutated_spike_windows; %get the data that tells us each channel the spike came from
        which_channels = spike_windows(cf,3); %get the channels of each spike
        spike_comes_from_good_channels = ismember(which_channels,good_channels); %get a filter for the good dimensions
        disp("Size Before Dimension Drop: "+string(length(the_cfs{k})))
        the_cfs{k} = cf(spike_comes_from_good_channels); %drop data from bad dimensions
        disp("Size after dimension drop: "+string(length(the_cfs{k})))
        % the_good_filt(k) = ~any(dim_filter); %if any of the dimensions are bad (i.e. cluster is seperable along that dimension) then the entire cluster is scrapped
        the_good_filt(k) = true; %edited by Luis David Davila on 05/07/2026
    end

end