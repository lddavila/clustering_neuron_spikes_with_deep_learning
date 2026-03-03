%updated by Luis David Davila and Alexander Friedman
function regrade_ntt_ver_2(the_filename, the_config)
%REGRADE_NTT Regrades a particular tetrode.
%   REGRADE_NTT(filename, save_dir)
%
%   'filename' is the path to the tetrode file.
%
%   'config' is the global spikesort configuration struct.
    
    filenames = setup_filenames(the_filename, the_config.save_dir);
    
    manual_clustered = fullfile(filenames.full_dir, the_config.MANUAL_DIR);
    manual_output = prepare_manual_output(manual_clustered, filenames);
    is_manual_clustered = ~isempty(manual_output) && size(manual_output, 2) >= 2;
    
    if the_config.ONLY_MANUAL_CLUSTERED && ~is_manual_clustered
        return
    end
    
    if exist(filenames.output, 'file') || is_manual_clustered
        [raw, timestamps, ~, ir, tvals, ~] = extract_raw(the_filename, the_config);
        wire_filter = find_live_wires(raw);
        r_raw = raw(wire_filter, :, :);
        if isempty(r_raw) || isempty(timestamps)
            return
        end
        r_tvals = tvals(wire_filter);
        r_ir = ir(wire_filter);
        interp_raw = interpolate_spikes(raw, the_config);
        % Fix interpolated spikes that hit threshhold
%         for w = 1:size(interp_raw, 1)
%             interp_raw(w, r_ir(w) - interp_raw(w, :, :) < r_ir(w) * 0.03) = r_ir(w);
%         end
        aligned = align_to_peak(interp_raw, tvals, ir);
        aligned = aligned(wire_filter, :, :);
        if exist(filenames.output, 'file')
            t = load(filenames.output);
            clusters = extract_clusters_from_output(timestamps * 1e-6, t.output, the_config.spikesort);
            grades = compute_gradings_ver_2(aligned, timestamps, r_tvals, clusters, the_config.spikesort);
            [final_grades, confidence] = compute_final_grades(grades, the_config.spikesort);
            means = cellmap(@(x) squeeze(mean(aligned(:, x, :), 2)), clusters);
            
            save_info(filenames.info, grades, final_grades, confidence, means, filenames.orig);
        end
        
        if is_manual_clustered
            manual_clusters = extract_clusters_from_output(timestamps * 1e-6, manual_output, the_config.spikesort);
            manual_grades = compute_gradings_ver_2(aligned, timestamps, r_tvals, manual_clusters, the_config.spikesort);
            [manual_final_grades, manual_confidence] = compute_final_grades(manual_grades, the_config.spikesort);
            manual_means = cellmap(@(x) squeeze(mean(aligned(:, x, :), 2)), manual_clusters);
            
            save_info(filenames.manual_info, manual_grades, manual_final_grades, manual_confidence, manual_means, filenames.orig);
            if exist(filenames.output, 'file')
                run_cluster_comparison_statistic(aligned, r_tvals, timestamps, t.output, manual_output, filenames.stat, the_config);
            end
        end
    end

end