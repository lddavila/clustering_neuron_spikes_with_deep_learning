function run_spikesort_ntt(filename, config)
%RUN_SPIKESORT_NTT Runs spike sorter on a particular tetrode.
%   RUN_SPIKESORT_NTT(filename, save_dir)
%
%   'filename' is the path to the tetrode file.
%
%   'config' is the global spikesort configuration struct.
    
    filenames = setup_filenames(filename, config.SAVE_DIRECTORY);
    
    if strncmp(config.MANUAL_DIR, '/', 1)
        manual_clustered = fullfile(config.MANUAL_DIR, filenames.session_name);
    else
        % KYLE FORMAT:
%         manual_clustered = fullfile(filenames.full_dir, config.MANUAL_DIR, kyle_dir(filenames));
        % ALEXANDER FORMAT:
        manual_clustered = fullfile(filenames.full_dir, config.MANUAL_DIR);
    end
    manual_output = prepare_manual_output(manual_clustered, filenames);
    is_manual_clustered = ~isempty(manual_output) && size(manual_output, 2) >= 2;
    
    if config.ONLY_MANUAL_CLUSTERED && isempty(manual_output)
        return
    end

    if ~config.FORCE_SPIKESORT
        if exist(filenames.output, 'file') && ~isempty(manual_output) && ~exist(filenames.stat, 'file')
            % TODO: Just get missing statistics if already clustered.
        elseif exist(filenames.output, 'file') || exist(filenames.done, 'file')
            fprintf('%s has already been processed. Skipping.\n', filename)
            return
        end
    end
    
    if config.DEBUG
        [raw, timestamps, good_spike_idx, ir, tvals, errmsg] = extract_raw(filename, config);
    else
        raw = [];
        try
            [raw, timestamps, good_spike_idx, ir, tvals, errmsg] = extract_raw(filename, config); %function which reads it
        catch
        end
    end
    
    wire_filter = find_live_wires(raw);
    
    if isempty(raw(wire_filter, :, :)) || isempty(good_spike_idx)
        msg = sprintf('Error extracting spikes from %s.\n%s\nSkipping.\n', filename, errmsg);
        disp(msg)
        create_done_file(filenames.done, msg);
        return
    end
    
    fprintf('Clustering %s...\n', filename)
    
    cluster_errmsg = '';
    if config.DEBUG
        [output, aligned, reg_timestamps] = run_spikesort_ntt_core(raw, timestamps, good_spike_idx, ir, tvals, filenames, config);
    else
        output = [];
        aligned = [];
        try
            [output, aligned, reg_timestamps] = run_spikesort_ntt_core(raw, timestamps, good_spike_idx, ir, tvals, filenames, config);
        catch err
            cluster_errmsg = getReport(err);
        end
    end
    if isempty(aligned)
        if isempty(cluster_errmsg)
            msg = sprintf('Error clustering. Skipping.\n');
        else
            msg = cluster_errmsg;
        end
        fprintf(msg);
        create_done_file(filenames.done, msg);
        return
    end
    
    fprintf('Done clustering %s.\n', filename)
    
    if is_manual_clustered
        fprintf('Starting manual comparison...\n');
        if config.DEBUG
            run_cluster_comparison_statistic(aligned, tvals(wire_filter), reg_timestamps, output, manual_output, filenames.stat, config);
        else
            try
                run_cluster_comparison_statistic(aligned, tvals(wire_filter), reg_timestamps, output, manual_output, filenames.stat, config);
            catch
                fprintf('Error running manual comparison.\n')
            end
        end
    end
end