function results = get_stats(directory)
%GET_STATS Finds all "_stat" output files and collects statistics for a
%given directory of spike sorting results.
%   results = GET_STATS(directory)
%
%   'directory' is the path to the root of the results directory.
%
%   'results' is a cell array containing results for each stat file found.

    results = [];
    mat_files = dir(fullfile(directory, '*.mat'));
    if isempty(mat_files)
        % Look at all subdirectories
        all_files = dir(directory);
        folders = all_files([all_files.isdir]);
        folders = sort({folders.name});
        for folder = folders
            name = folder{1};
            if ~isempty(name) && ~strcmp(name(1), '.')
                tmp = get_stats(fullfile(directory, name));
                results = [results tmp];
            end
        end
        return
    end
    mat_files = sort({mat_files.name});
    results = cell(1, length(mat_files));
    for k = 1:length(mat_files)
        filename = mat_files{k};
        if ~isempty(regexp(filename, '.+_(coact|new|multispike|info|class|stat)\.', 'match'))
            continue
        end
        [~, corename, ~] = fileparts(filename);
        try
            info_file = fullfile(directory, sprintf('%s_info.mat', corename));
            stat_file = fullfile(directory, sprintf('%s_stat.mat', corename));
            if ~exist(stat_file, 'file') || ~exist(info_file, 'file')
                fprintf('%s missing stat file\n', fullfile(directory, filename));
                continue
            end
            info = load(info_file);
            stats = load(stat_file);
%             orig_dir = fileparts(info.orig_filename);
%             human_file = fullfile(orig_dir, 'clustered');
%             human = [];
%             if exist(human_file, 'dir')
%                 files = dir(fullfile(human_file, sprintf('%s*.mat', lower(corename))));
%                 if isscalar(files)
%                     clustered = load(fullfile(human_file, files.name));
%                 else
%                     clustered = [];
%                     for n = 1:length(files)
%                         f = files(n);
%                         if strcmp(f.name, sprintf('%s.mat', lower(corename)))
%                             clustered = load(fullfile(human_clustered, f.name));
%                             break
%                         end
%                     end
%                 end
%                 if ~isempty(clustered)
%                     field_name = fields(clustered);
%                     if isscalar(field_name)
%                         human = clustered.(field_name{1});
%                     end
%                 end
%             end
%             if isempty(human)
%                 continue
%             end
        catch
            continue
        end
%         m = load(fullfile(directory, filename));
%         
%         clusters = sort(unique(m.output(:, 2)));
%         cts = cell(1, length(clusters));
%         for n = 1:length(clusters)
%             cts{n} = round_times(m.output(m.output(:, 2) == clusters(n), 1));
%         end
%         
%         [stats, hts] = compare_to_human2(cts, human);
%         numspikes = cellfun(@length, hts);
%         
%         if exist(info.orig_filename, 'file')
%             [raw, ts, ~, ~, tvals] = extract_raw(info.orig_filename, false);
%             % Remove wires with no data.
%             wire_filter = false(1, size(raw, 1));
%             for wire = 1:size(raw, 1)
%                 if any(any(squeeze(raw(wire, :, :))))
%                     wire_filter(wire) = true;
%                 end
%             end
% 
%             resized_raw = raw(wire_filter, :, :);
%             resized_tvals = tvals(wire_filter);
%             clear raw tvals
%             ts = round(ts * 1e-3);
%             cf = cell(size(cts));
%             hcf = cell(size(hts));
%             for n = 1:length(clusters)
%                 [~, bin] = histc(cts{n}, ts);
%                 cf{n} = bin;
%             end
%             for n = 1:length(hts)
%                 [~, bin] = histc(hts{n}, ts);
%                 hcf{n} = bin;
%             end
%             ts_in_micro = ts * 1e3;
%             comp_gradings = compute_gradings(resized_raw, ts_in_micro, resized_tvals, cf);
%             human_gradings = compute_gradings(resized_raw, ts_in_micro, resized_tvals, hcf);
%         else
%             comp_gradings = [];
%             human_gradings = [];
%         end
        if ~isfield(stats, 'clusters_found')
            stats.clusters_found = [];
        end
        
        result = struct('stats', stats.stat, 'comp_gradings', info.grades, ...
                        'manual_gradings', stats.manual_gradings, ...
                        'clusters_found', stats.clusters_found, ...
                        'orig', info.orig_filename);
        results{k} = result;
    end
    results = cell2mat(results(~cellfun(@isempty, results)));
end
