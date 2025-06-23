function [final_grades, confidence] = compute_final_grades(grades, config)
%COMPUTE_FINAL_GRADES Computes a final grade for each cluster based on the
%various grades computed.
%   final_grades = COMPUTE_FINAL_GRADES(grades)
%
%   See also COMPUTE_GRADINGS.

    num_clusters = size(grades, 1);
    final_grades = nan(1, num_clusters);
    confidence = ones(1, num_clusters);
    
    for k = 1:num_clusters
        lratio = grades(k, 1); %
        percent_short_isi = grades(k, 3); %Pay attention
        below_threshold = grades(k, 4); %pay attention 
        isolation_dist = grades(k, 5);
        min_bhat = grades(k, 9); %pay attention
        bhat_unsorted = grades(k, 10);
        snr = grades(k, 18);
        
        bhat_mua = grades(k, 19);
        bhat_nearcl = grades(k, 20);
        recording_perc = grades(k, 22);
        mpc = grades(k, 23);
        num_live_wires = grades(k, 24);
        spike_quarter_width = grades(k, 25);
        firing_rate = grades(k, 26);
        has_valley = grades(k, 27);
        
        fg = NaN;
        
        if snr >= 0.25 %check deeper into this
            fg = -1;
        elseif recording_perc < 0.25 
            fg = -2;
        elseif mpc > 0.75
            fg = -3;
        elseif below_threshold > 0.35 && isolation_dist < 1
            fg = -4;
        elseif num_live_wires <= 2
            fg = -5;
        elseif spike_quarter_width < 90
            fg = -6;
        elseif percent_short_isi > config.params.GR_MAX_SHORT_ISI_PERCENT
            fg = -7;
        elseif firing_rate > 50
            fg = -8;
        elseif lratio > 0.3 && isolation_dist < 5 % Most likely too contaminated
            fg = -9;
            confidence(k) = 0.8;
        elseif ~has_valley
            fg = -10;
        elseif below_threshold > 0.25 && isolation_dist < 1
            fg = 1;
        elseif ~isnan(bhat_mua) && (bhat_mua < 1.5 || ...
                (below_threshold > 0.1 && bhat_nearcl < 0.5)) && ...
                isolation_dist < 1
            fg = 2;
        elseif ((min_bhat > 4 && (isnan(bhat_unsorted) || bhat_unsorted > 2)) || lratio < 0.05) && ...
                below_threshold < 0.1 && ...
                bhat_nearcl == Inf
            fg = 5;
        elseif (lratio < 0.1)
            if (isnan(bhat_unsorted) || bhat_unsorted > 1) && min_bhat > 2 && ...
                    percent_short_isi < config.params.GR_MAX_SHORT_ISI_PERCENT && ...
                    below_threshold < 0.1
                fg = 4;
            else
                fg = 3;
            end
            if below_threshold > 0.15
                confidence(k) = 0.5;
            end
        else
            fg = 2;
        end

        final_grades(k) = fg;
    end
end

