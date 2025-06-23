function new_statistics(results)
%NEW_STATISTICS New way of analyzing statistics results.
%   NEW_STATISTICS(results)
%
%   'results' is a cell array, usually acquired by using "get_stats"
%
%   See also GET_STATS.

    fprintf('Manual clusters found by computer:\n')
    [tc1, mtc1, btc1, find_ratio, med_find_ratio, bad_find_ratio, hgs, gs] = new_statistics_inner(results, true);
    fprintf('5 find ratio: %.2f\n', 100* gs.g5.fc/gs.g5.tc);
    fprintf('4 find ratio: %.2f\n', 100* gs.g4.fc/gs.g4.tc);
    fprintf('3 find ratio: %.2f\n', 100 * gs.g3.fc/gs.g3.tc);
    fprintf('Totals: %d, %d, %d, %d\n', gs.g5.tc, gs.g4.tc, gs.g3.tc, gs.artifacts.tc)
    
%     fprintf('\n')
%     
%     fprintf('Computer clusters found in manual clustering:\n')
%     [tc2, mtc2, btc2, find_ratio, med_find_ratio, bad_find_ratio, ~, gs2] = new_statistics_inner(results, false);
%     fprintf('Good find ratio: %.2f\n', find_ratio);
%     fprintf('Mediocre find ratio: %.2f\n', med_find_ratio);
%     fprintf('Bad find ratio: %.2f\n', bad_find_ratio);
%     fprintf('Totals: %d, %d, %d, %d\n', tc2, mtc2, btc2, gs2.artifacts.tc);
%     
%     fprintf('\n')
    
%     a = ~isinf(hgs(:, 2)) & hgs(:, 2) < 3;
    
%     figure;
%     hold on
%     [n, xout] = hist(hgs(a, 1), 50);
%     first = xout < 0.11;
%     second = xout > 0.09 & xout < 0.31;
%     third = xout > 0.29 & xout < 0.51;
%     fourth = xout > 0.49;
%     barplot(xout', n', 'g', first)
%     barplot(xout', n', 'y', second)
%     barplot(xout', n', 'r', third)
%     barplot(xout', n', 'k', fourth)
% %     dg_plotShadeCL(h, [xout(first)', zeros(sum(first), 1), n(first)'], 'FaceColor', 'b', 'FaceAlpha', 0.9);
% %     dg_plotShadeCL(h, [xout(second)', zeros(sum(second), 1), n(second)'], 'FaceColor', 'g', 'FaceAlpha', 0.9);
% %     dg_plotShadeCL(h, [xout(third)', zeros(sum(third), 1), n(third)'], 'FaceColor', 'r', 'FaceAlpha', 0.9);
% %     dg_plotShadeCL(h, [xout(fourth)', zeros(sum(fourth), 1), n(fourth)'], 'FaceColor', 'k', 'FaceAlpha', 0.9);
% %     bar(xout, n, 1)
% %     plot([0.1, 0.1], [0, max(n)], 'r')
% %     plot([0.3, 0.3], [0, max(n)], 'r')
% %     plot([0.5, 0.5], [0, max(n)], 'r')
% %     xs = xlim;
% %     plot([xs(2), xs(2)], [0, max(n)], 'r')
%     axis tight
%     title('Histogram Across Clusters in the Manual Database')
%     xlabel('LRatio/Isolation')
%     ylabel('Number of Clusters')
%     legend('Good', 'Mediocre', 'Bad', 'Very Bad')
%     
%     fprintf('LRatio. Percentage of clusters worse than "Bad": %.2f%%\n', 100 * sum(hgs(:, 1) > 0.5)/size(hgs, 1))
%     
%     figure
%     hold on
%     [n, xout] = hist(hgs(a, 2), 50);
%     first = xout > 0.78;
%     second = xout > 0.45 & xout < 0.85;
%     third = xout < 0.51;
%     barplot(xout', n', 'g', first)
%     barplot(xout', n', 'r', second)
%     barplot(xout', n', 'k', third)
% %     bar(xout, n, 1)
% %     plot([0.8, 0.8], [0, max(n)], 'r')
% %     plot([0.5, 0.5], [0, max(n)], 'r')
%     axis tight
%     title('Histogram Across Clusters in the Manual Database')
%     xlabel('Tightness')
%     ylabel('Number of Clusters')
%     legend('Good', 'Mediocre/Bad', 'Very Bad')
%     
%     fprintf('Tightness. Percentage of clusters worse than "Bad": %.2f%%\n', 100 * sum(hgs(:, 2) < 0.5)/size(hgs, 1))
%     
%     figure
%     hold on
%     [n, xout] = hist(hgs(a, 4), 50);
%     first = xout < 0.05;
%     second = xout > 0.01 & xout < 0.12;
%     third = xout > 0.09 & xout < 0.51;
%     fourth = xout > 0.49;
%     barplot(xout', n', 'g', first)
%     barplot(xout', n', 'y', second)
%     barplot(xout', n', 'r', third)
%     barplot(xout', n', 'k', fourth)
%     legend('Good', 'Mediocre', 'Bad', 'Very Bad')
% %     bar(xout, n, 1)
% %     plot([0.01, 0.01], [0, max(n)], 'r')
% %     plot([0.1, 0.1], [0, max(n)], 'r')
% %     plot([0.5, 0.5], [0, max(n)], 'r')
%     axis tight
%     title('Histogram Across Clusters in the Manual Database')
%     xlabel('Incompleteness')
%     ylabel('Number of Clusters')
%     
%     fprintf('Incompleteness. Percentage of clusters worse than "Bad": %.2f%%\n', 100 * sum(hgs(:, 4) > 0.5)/size(hgs, 1))
%     
%     fprintf('Total. Percentage of clusters worse than "Bad": %.2f%%\n', 100 * sum(hgs(:, 1) > 0.5 | hgs(:, 4) > 0.5 | hgs(:, 2) < 0.5)/size(hgs, 1))
end

function barplot(xout, n, color, range)
    dg_plotShadeCL(gca, [xout(range), zeros(size(xout(range))), n(range)], 'FaceColor', color, 'FaceAlpha', 0.9);
end

function [tc, mtc, btc, find_ratio, med_find_ratio, bad_find_ratio, hgs, grade_stats] = new_statistics_inner(results, do_manual)
%     total = 0;
    g = struct('tc', 0, 'fc', 0);
    grade_stats = struct();
    grade_stats.good = g;
    grade_stats.med = g;
    grade_stats.bad = g;
    grade_stats.g1 = g;
    grade_stats.g2 = g;
    grade_stats.g3 = g;
    grade_stats.g4 = g;
    grade_stats.g5 = g;
    grade_stats.artifacts = g;
    
    good = g;
    med = g;
    bad = g;
    g1 = g;
    g2 = g;
    g3 = g;
    g4 = g;
    g5 = g;
    
    artifacts = g;
    
    config = spikesort_config();

%     good_percs = [];
%     med_percs = [];
%     bad_percs = [];

    hgs = [];
    cgs = [];
    
    fgs = [];

    for k = 1:length(results)
        result = results(k);
        stats = result.stats;
        if do_manual
            cg = result.comp_gradings;
            hg = result.manual_gradings;
        else
            cg = result.manual_gradings;
            hg = result.comp_gradings;
            stats = stats';
        end
        if isempty(cg)
            continue
        end
        clusters_found = false(size(stats, 1), 1);
        for m = 1:length(clusters_found)
            if min(stats(m, :)) < 0.75
                clusters_found(m) = true;
            end
        end
        fname = result.orig;
%         if ~isempty(regexp(fname, 'vta[0-9]+', 'match'))
%             continue
%         end
    %     hg = [hg result.numspikes];
        hgs = [hgs ; hg(:, 1:9)];
        cgs = [cgs ; cg(:, 1:9)];
        [final_grades, confidence] = compute_final_grades(hg, config.spikesort);
        [cfinal_grades, cconfidence] = compute_final_grades(cg, config.spikesort);
        for hum_idx = 1:size(stats, 1)
            fg = final_grades(hum_idx);
            conf = confidence(hum_idx);
            fgs = [fgs fg];
            cf = clusters_found(hum_idx);
            
            if fg == 5 && hg(hum_idx, 6) >= 200
                g5.tc = g5.tc + 1;
                if cf
                    [~, idx] = min(stats(hum_idx, :));
                    if cfinal_grades(idx) >= 3
                        g5.fc = g5.fc + 1;
                    else
%                         disp(cfinal_grades(idx))
                        if cfinal_grades(idx) == 2
                            
                        end
                    end
%                     if hg(:, 1) < 0.01
%                         fprintf('5: %d %s\n', hum_idx, fname)
%                     end
                else
%                     fprintf('5: %d %s\n', hum_idx, fname)
                end
            elseif fg == 4 && hg(hum_idx, 6) >= 200
                g4.tc = g4.tc + 1;
                if cf
                    [~, idx] = min(stats(hum_idx, :));
                    if cfinal_grades(idx) >= 3
                        g4.fc = g4.fc + 1;
                    end
%                     [~, idx] = min(stats(hum_idx, :));
%                         fprintf('4: %d %s\n', idx, fname)
                end
            elseif fg == 3 && hg(hum_idx, 6) >= 200
                g3.tc = g3.tc + 1;
                if cf
                    [~, idx] = min(stats(hum_idx, :));
                    if cfinal_grades(idx) >= 3
                        g3.fc = g3.fc + 1;
                    else
%                         disp(sum(stats(hum_idx, :) < 0.75))
                        disp(cfinal_grades(idx))
                        if cfinal_grades(idx) == 2
                            
                        end
                    end
%                     if hg(hum_idx, 4) < 0.05 && hg(hum_idx, 4) > 0
%                         fprintf('3: %d %s\n', hum_idx, fname)
%                     end
                end
            elseif fg == 2
                g2.tc = g2.tc + 1;
                if cf
                    [~, idx] = min(stats(hum_idx, :));
                    if cfinal_grades(idx) >= 3
                        g2.fc = g2.fc + 1;
                    end
%                     [~, idx] = min(stats(hum_idx, :));
%                     fprintf('2: %d %s\n', idx, fname)
                end
            elseif fg == 1
                g1.tc = g1.tc + 1;
                if cf
                    g1.fc = g1.fc + 1;
                    [~, idx] = min(stats(hum_idx, :));
%                     fprintf('1: %d %s\n', idx, fname)
                end
            elseif fg < 0
                artifacts.tc = artifacts.tc + 1;
            end
            
%             if fg == -1
%                 fprintf('%d %d %.3f %s\n', k, hum_idx, hg(hum_idx, 18), fname);
%             end
            
            if hg(hum_idx, 4) > 0.2 && hg(hum_idx, 6) > 1000 && hg(hum_idx, 4) < 0.3 && hg(hum_idx, 1) < 0.05
%                 fprintf('%d %d %.3f %s\n', k, hum_idx, hg(hum_idx, 4), fname);
            end
            
            if ismember(fg, [5]) && hg(hum_idx, 6) >= 200
                good.tc = good.tc + 1;
                if cf
                    good.fc = good.fc + 1;
                end
            elseif ismember(fg, [3,4]) && hg(hum_idx, 6) >= 200
                if conf == 1
                    med.tc = med.tc + 1;
                    if cf
                        med.fc = med.fc + 1;
                    else
%                         fprintf('%d %d %s\n', k, hum_idx, fname);
                    end
                end
            elseif ismember(fg, [1,2]) && hg(hum_idx, 6) >= 200
                bad.tc = bad.tc + 1;
                if cf
                    bad.fc = bad.fc + 1;
                end
            end
        end
    %     total_clusters = total_clusters + size(stats, 2);
%         for hum_idx = 1:size(stats, 1)
%             if hg(hum_idx, 1) < 0.1 && hg(hum_idx, 4) < 0.1 && hg(hum_idx, 2) > 0.6 && hg(hum_idx, 6) > 800 %&& hg(a, 2) > 0.5 && hg(a, 3) < 0.05 ...
%                     %&& hg(a, 4) == 0 && hg(a, 6) > 300 %&& hg(a, 5) > 10
%                 tc = tc + 1;
%                 if clusters_found(hum_idx);
%                     fc = fc + 1;
%                 else
%                     fprintf('%s\n', fname)
%                 end
% %                 if perc(1) > 0.7 && perc(2) > 0.5 && (~do_human || (cg(maxind, 1) < 0.1 && cg(maxind, 2) > 0.8))
% %                     fc = fc + 1;
% %                     good_percs = [good_percs perc(1)];
% %                 else
% %                     if false && ~do_human && perc(1) < 0.2
% % %                         disp(k)
% %                         disp(hum_idx)
% %                         disp(hg(hum_idx,6))
% %                         disp(fname)
% %                     end
% %                     [~,w] = min(perc);
% %                     if false && w == 2 && ~do_human
% %                         disp('too big')
% %                     end
% %                 end
%             elseif hg(hum_idx, 1) < 0.3 && hg(hum_idx, 2) > 0.5 && hg(hum_idx, 3) < 0.05 ...
%                     && hg(hum_idx, 4) < 0.1 && hg(hum_idx, 6) > 1000 %&& hg(a, 5) > 5
%                 mtc = mtc + 1;
%                 if clusters_found(hum_idx)
%                     mfc = mfc + 1;
%                 else
% %                     disp('hi')
%                 end
% %                 if perc(1) > 0.5 && perc(2) > 0.3
% %                     mfc = mfc + 1;
% %                     med_percs = [med_percs perc(1)];
% %                 end
%             elseif hg(hum_idx, 1) < 0.5 && hg(hum_idx, 2) > 0.5 && hg(hum_idx, 3) < 0.1 ...
%                     && hg(hum_idx, 4) < 0.5 && hg(hum_idx, 6) > 1000 && hg(hum_idx, 5) > 1
%                 btc = btc + 1;
%                 if clusters_found(hum_idx)
%                     bfc = bfc + 1;
%                 end
% %                 if perc(1) > 0.5 && perc(2) > 0.3
% %                     bfc = bfc + 1;
% %                     bad_percs = [bad_percs perc(1)];
% %                 end
%             end
%         end
    end

%     mean_perc = mean(good_percs);
%     mean_med_perc = mean(med_percs);
%     mean_bad_perc = mean(bad_percs);
    find_ratio = good.fc/good.tc * 100;
    med_find_ratio = med.fc/med.tc * 100;
    bad_find_ratio = bad.fc/bad.tc * 100;
    
    tc = good.tc;
    mtc = med.tc;
    btc = bad.tc;
    
    grade_stats.good = good;
    grade_stats.med = med;
    grade_stats.bad = bad;
    grade_stats.g1 = g1;
    grade_stats.g2 = g2;
    grade_stats.g3 = g3;
    grade_stats.g4 = g4;
    grade_stats.g5 = g5;
    grade_stats.artifacts = artifacts;
    
    [x, n] = hist(fgs, unique(fgs))
end