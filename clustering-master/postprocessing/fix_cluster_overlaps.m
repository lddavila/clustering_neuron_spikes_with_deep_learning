function cf = fix_cluster_overlaps(source, cf, config)
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

    if length(cf) > 1
        peaks = get_peaks(source, true);
        data = peaks';
        for k = 1:length(cf)-1
            ck = cf{k};
            if isempty(ck)
                continue
            end
            for l = k+1:length(cf)
                cl = cf{l};
                if isempty(cl)
                    continue
                end
                isect = intersect(ck, cl);
                if ~isempty(isect)
                    excl_ck = setdiff(ck, isect);
                    excl_cl = setdiff(cl, isect);
                    data_k = data(excl_ck, :);
                    data_l = data(excl_cl, :);
                    data_isect = data(isect, :);
                    data_filt = find(find_singular_cols(data_k) & find_singular_cols(data_l));
                    for q = 1:length(data_filt)
                        dim = data_filt(q);
                        rk = compute_lratio(data_isect(:, dim), data_k(:, dim));
                        rl = compute_lratio(data_isect(:, dim), data_l(:, dim));
                        data_k(:, dim) = (1 - rk) * data_k(:, dim);
                        data_l(:, dim) = (1 - rl) * data_l(:, dim);
                    end
                    try
                        m_k = mahal(data_isect(:, data_filt), data_k(:, data_filt));
                        m_l = mahal(data_isect(:, data_filt), data_l(:, data_filt));
                    catch
                        m_k = 0;
                        m_l = 0;
                    end
                    both_clusters = union(ck, cl);
                    thresh_min = min(length(ck), length(cl)) * ...
                        config.params.FO_MIN_OVERLAP_PERCENT;
                    if length(isect) > thresh_min
                        if sum(m_k < m_l) > sum(m_l < m_k)
                            ck = both_clusters;
                            cl = [];
                        else
                            cf{k} = [];
                            cf{l} = both_clusters;
                            break
                        end
                    else
                        ck = union(excl_ck, isect(m_k < m_l));
                        cl = union(excl_cl, isect(m_l < m_k));
                    end
                    cf{k} = ck;
                    cf{l} = cl;
                end
            end
        end
    end
    cf = cf(~cellfun('isempty', cf));
end