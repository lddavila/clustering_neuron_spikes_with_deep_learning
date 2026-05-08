%edited by Luis David Davila and Alexander Friedman
function the_cf = fix_cluster_overlaps(the_source, the_cf, the_config)
%FIX_CLUSTER_OVERLAPS Settles ties between clusters when a certain spike
%appears in two clusters. If many spikes overlap, the clusters are merged.
%   cf = FIX_CLUSTER_OVERLAPS(source, cf)
%
%   'source' is a 3d array with the dimensions:
%   1) wire number
%   2) spike number
%   3) index in spike samples
%
%   'cf' is a cell array of indices for each cluster.

    if length(the_cf) > 1
        peaks = get_peaks(the_source, true); %get the peaks
        data = peaks'; %transpose the peak data
        for k = 1:length(the_cf)-1 %loop through all clusters starting at 1
            ck = the_cf{k}; %get the indexes for the current cluster
            if isempty(ck) %forget the current cluster if it has no clusters
                continue
            end
            for l = k+1:length(the_cf) %loop through all clusters starting at k+1
                cl = the_cf{l}; %get the indexes for the comparison cluster
                if isempty(cl)
                    continue
                end
                isect = intersect(ck, cl); % get all spikes that the current cluster and comparison cluster have in common
                if ~isempty(isect) %ensure the intersection isn't empty
                    excl_ck = setdiff(ck, isect); %get all the spikes in the current cluster but not in the intersection set
                    excl_cl = setdiff(cl, isect); %get all the spikes in the comparison cluster but not in the intersection set
                    data_k = data(excl_ck, :); %get the peaks across all wires for the current cluster
                    data_l = data(excl_cl, :); %get the peaks for the comparison cluster
                    data_isect = data(isect, :); %get the peaks which exist in both the current & comparison cluster
                    data_filt = find(find_singular_cols(data_k) & find_singular_cols(data_l)); %check for singular cols in both data sets
                    for q = 1:length(data_filt) %cycle through each dimension
                        dim = data_filt(q); %get all the data for the current dimension AKA channel
                        rk = compute_lratio(data_isect(:, dim), data_k(:, dim)); %get the lratio between the intersecting data and the current cluster
                        rl = compute_lratio(data_isect(:, dim), data_l(:, dim)); %get the lratio between the intersecting data and the comparison cluster
                        data_k(:, dim) = (1 - rk) * data_k(:, dim); %take 1-current_lratio and multiply the dimension data for it
                        data_l(:, dim) = (1 - rl) * data_l(:, dim); %take 1-comparison lratio and multiply the dimension data
                    end
                    try
                        %OG LINE: m_k = mahal(data_isect(:, data_filt), data_k(:, data_filt));
                        m_k = mahal_fixed_for_num_unstable(data_isect(:, data_filt), data_k(:, data_filt)); %get the mahal distance between the intecting data and the current cluster dimension
                        %OG LINE: m_l = mahal(data_isect(:, data_filt), data_l(:, data_filt));
                        m_l = mahal_fixed_for_num_unstable(data_isect(:, data_filt), data_l(:, data_filt)); %get the mahal distance between the intersecting data and the comparison cluster dimension
                    catch
                        m_k = 0; %in case of numerically unstable data we just set these values to 0 effectively creating a tie for this feature
                        m_l = 0;
                    end
                    %OG LINE: both_clusters = union(ck, cl); %OLD
                    %OG LINE: thresh_min = min(length(ck), length(cl)) * ...
                     %OG LINE  %the_config.params.FO_MIN_OVERLAP_PERCENT; %get the minimum number of spikes needed in the intersection set to merge clusters
                                                                    
                    if length(isect) > thresh_min %are there enough spikes in the intersection set to justify a merge
                        if sum(m_k < m_l) > sum(m_l < m_k) %weird way to write a condition: check if the current mahal distance is greater than the comparison mahal distance
                            ck = both_clusters; %if so then join the 2 clusters into the current cluster
                            cl = []; %empty the comparison cluster
                        else
                            the_cf{k} = []; %if not then empty the current cluster
                            the_cf{l} = both_clusters; %merge the 2 clusters into the comparison cluster
                            break %do not continue the loop as the current cluster is now empty
                        end
                    else
                        ck = union(excl_ck, isect(m_k < m_l)); %any spikes in the intersection set whose current mahal distance is less than the comparison mahal distance are assigned to the current cluster
                        cl = union(excl_cl, isect(m_l < m_k)); %any spikes in the intersection set whose comparison mahal distance is less than the comparison mahal distance are assigned to the comparison cluster
                    end
                    the_cf{k} = ck; %update the cluster list with the current cluster 
                    the_cf{l} = cl; %update the cluster list with the comparison cluster
                end
            end
        end
    end
    the_cf = the_cf(~cellfun('isempty', the_cf)); %remove any empty clusters created through joining

    %this function seems to have a weakness it doesn't have handling for
    %0-0 mahal distance when it fails
    %and if a gigantic cluster is formed and compared to a smaller cluster
    %it will merge them and that can snow ball into a single large cluster
    %essentially eating all the smaller clusters
end