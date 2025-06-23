function run_kk_compare(filename, clu_dir, out_dir)
    f = fopen(filename);
    g = textscan(f,'%s','delimiter','\n');
    fclose(f);
    ntt_files = sort(g{1});
    
    clu_files = dir(fullfile(clu_dir, '*.clu.0'));
    if isempty(clu_files)
        fprintf('Clustered files not found.\n')
        return
    end
    
    clu_files = sort({clu_files.name});
    if length(ntt_files) < length(clu_files)
        fprintf('The number of clustered files does not match up.\n')
        return
    end
    
    config = spikesort_config();
    count = 0;
    
    for k = 1:length(clu_files)
        clu_filename = fullfile(clu_dir, clu_files{k});
        [~, basename, ~] = fileparts(clu_filename);
        ntt_scan = textscan(basename, 'tt%d');
        ntt_idx = ntt_scan{1};
        ntt_filename = ntt_files{ntt_idx};
        
        % Get the manual clusters.
        output = get_manual_output(ntt_filename);
        if isempty(output)
            fprintf('No manual clusters found.\n')
            continue
        end
        
        [raw, timestamps, ~, ir, tvals] = extract_raw(ntt_filename, config);
        wire_filter = find_live_wires(raw);
        r_raw = raw(wire_filter, :, :);
        if isempty(r_raw) || isempty(timestamps)
            fprintf('Empty tetrode.\n')
            return
        end
        
        ts_seconds = timestamps ./ 1e6;
%         manual_cf = extract_clusters_from_output(ts_seconds, output, config.spikesort);
        
        % Work with the clustered files now
        [kk_cf, kk_output] = get_kk_cf(clu_filename, ts_seconds);
        
        run_comparison(raw, timestamps, ir, tvals, config, output, kk_cf, kk_output, basename, out_dir);
        count = count + 1;
    end
    fprintf('Count: %d\n', count);
end

function run_comparison(raw, ts, ir, tvals, config, manual_output, kk_cf, kk_output, basename, out_dir)
    disp('Made it here!')
    full_kk_output = nan(size(kk_output, 1), 130);
    full_kk_output(:, 1:2) = kk_output;
    full_raw = reshape(permute(raw, [3 1 2]), 128, [])';
    full_kk_output(:, 3:end) = full_raw;
    ntt_output = fullfile(out_dir, sprintf('%s.ntt', basename));
    mat_filename = fullfile(out_dir, sprintf('%s.mat', basename));
    output = kk_output;
    save(mat_filename, 'output');
    mk_dg_cutClust2Nlx(full_kk_output, ntt_output, ir, tvals);
    
    wire_filter = find_live_wires(raw);
    interp_raw = interpolate_spikes(raw, config);
    aligned = align_to_peak(interp_raw, tvals, ir);
    aligned = aligned(wire_filter, :, :);
    stat_filename = fullfile(out_dir, sprintf('%s_stat.mat', basename));
    run_cluster_comparison_statistic(aligned, tvals(wire_filter), ts, kk_output, manual_output, stat_filename, config);
    
    grades = compute_gradings_ver_2(aligned, ts, tvals(wire_filter), kk_cf, config.spikesort);
    [final_grades, confidence] = compute_final_grades(grades, config.spikesort);
    info_filename = fullfile(out_dir, sprintf('%s_info.mat', basename));
    save_info(info_filename, grades, final_grades, confidence, {}, '');
end

function [kk_cf, kk_output] = get_kk_cf(clu_filename, ts_seconds)
    f = fopen(clu_filename);
    g = textscan(f,'%d','delimiter','\n');
    fclose(f);
    cluster_idx = cell2mat(g);
    cluster_idx = cluster_idx(2:end);
    cluster_nums = sort(unique(cluster_idx));
    kk_cf = cell(1, length(cluster_nums));
    for idx = 1:length(cluster_nums)
        cluster_num = cluster_nums(idx);
        kk_cf{idx} = find(cluster_idx == cluster_num);
    end
    
    kk_output = nan(length(ts_seconds), 2);
    kk_output(:, 1) = ts_seconds;
    kk_output(:, 2) = cluster_idx;
end

function output = get_manual_output(ntt_filename)
    output = [];
    [path, basename, ~] = fileparts(ntt_filename);
    [parent_path, ~, ~] = fileparts(path);
    ttnum_r = regexp(lower(basename), '\d+', 'match');
    ttnum = str2double(ttnum_r);
%     format_str = sprintf('*_%03d*.mat', ttnum - 1);
    format_str = sprintf('%s*.mat', basename);
    parent_path = fullfile(path, 'clustered');
    mat_files = dir(fullfile(parent_path, format_str));

    manual_output = [];

    % If the number of such corresponding files is exactly 1, that's
    % the one. Otherwise, choose the one that matches best.
    if isscalar(mat_files)
        clustered = load(fullfile(parent_path, mat_files.name));
    else
        clustered = [];
        for l = 1:length(mat_files)
            f = mat_files(l);
            if strcmp(f.name, sprintf('%s.mat', lower(basename)))
                clustered = load(fullfile(parent_path, f.name));
                break
            end
        end
    end

    % If we have found a matching .mat file, 'clustered' shouldn't be
    % empty, so get the data in the .mat file.
    % TODO: Maybe move this into the for loop above...? Maybe not.
    if ~isempty(clustered)
        field_name = fields(clustered);
        if isscalar(field_name)
            manual_output = clustered.(field_name{1});
        end
    end

    if ~isempty(manual_output)
        timestamp_col = [];
        cluster_col = [];

        % Find the timestamp column and the cluster column in the
        % output matrix.

        for k = 1:size(manual_output, 2)
            col = manual_output(:, k);
            if all(col >= 0)
                ucol = unique(col);
                if isscalar(ucol) || min(diff(ucol)) == 1
                    if isempty(cluster_col) || max(cluster_col) < max(ucol)
                        cluster_col = col;
                    end
                elseif all(diff(col) >= 0) && isempty(timestamp_col)
                    timestamp_col = col;
                end
            end
        end

        % Only if we find those columns can we make our final output
        % matrix.
        if ~isempty(timestamp_col) && ~isempty(cluster_col)
            output = [timestamp_col cluster_col];
        end
    end
end