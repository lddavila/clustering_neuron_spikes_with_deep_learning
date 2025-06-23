function regrade_ntt(filename, config)
%REGRADE_NTT Regrades a particular tetrode.
%   REGRADE_NTT(filename, save_dir)
%
%   'filename' is the path to the tetrode file.
%
%   'config' is the global spikesort configuration struct.
    
    filenames = setup_filenames(filename, config.save_dir);
    
    manual_clustered = fullfile(filenames.full_dir, config.MANUAL_DIR);
    manual_output = prepare_manual_output(manual_clustered, filenames);
    is_manual_clustered = ~isempty(manual_output) && size(manual_output, 2) >= 2;
    
    if config.ONLY_MANUAL_CLUSTERED && ~is_manual_clustered
        return
    end
    
    if exist(filenames.output, 'file') || is_manual_clustered
        [raw, timestamps, ~, ir, tvals, ~] = extract_raw(filename, config);
        wire_filter = find_live_wires(raw);
        r_raw = raw(wire_filter, :, :);
        if isempty(r_raw) || isempty(timestamps)
            return
        end
        r_tvals = tvals(wire_filter);
        r_ir = ir(wire_filter);
        interp_raw = interpolate_spikes(raw, config);
        % Fix interpolated spikes that hit threshhold
%         for w = 1:size(interp_raw, 1)
%             interp_raw(w, r_ir(w) - interp_raw(w, :, :) < r_ir(w) * 0.03) = r_ir(w);
%         end
        aligned = align_to_peak(interp_raw, tvals, ir);
        aligned = aligned(wire_filter, :, :);
        if exist(filenames.output, 'file')
            t = load(filenames.output);
            clusters = extract_clusters_from_output(timestamps * 1e-6, t.output, config.spikesort);
            grades = compute_gradings_ver_2(aligned, timestamps, r_tvals, clusters, config.spikesort);
            [final_grades, confidence] = compute_final_grades(grades, config.spikesort);
            means = cellmap(@(x) squeeze(mean(aligned(:, x, :), 2)), clusters);
            
            save_info(filenames.info, grades, final_grades, confidence, means, filenames.orig);
        end
        
        if is_manual_clustered
            manual_clusters = extract_clusters_from_output(timestamps * 1e-6, manual_output, config.spikesort);
            manual_grades = compute_gradings_ver_2(aligned, timestamps, r_tvals, manual_clusters, config.spikesort);
            [manual_final_grades, manual_confidence] = compute_final_grades(manual_grades, config.spikesort);
            manual_means = cellmap(@(x) squeeze(mean(aligned(:, x, :), 2)), manual_clusters);
            
            save_info(filenames.manual_info, manual_grades, manual_final_grades, manual_confidence, manual_means, filenames.orig);
            if exist(filenames.output, 'file')
                run_cluster_comparison_statistic(aligned, r_tvals, timestamps, t.output, manual_output, filenames.stat, config);
            end
        end
    end

end