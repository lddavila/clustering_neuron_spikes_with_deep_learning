function run_spikesort(directory)
%RUN_SPIKESORT Runs spike sorter on all tetrodes in a directory.
%   RUN_SPIKESORT(directory)
%
%   'directory' is the path to the directory containing tetrodes.

    config = spikesort_config();
    directory = regexprep(directory, '^~', getenv('HOME'));
    
    ntt_files = dir(fullfile(directory, '*.ntt'));
    if isempty(ntt_files)
        if config.RECURSIVE_SPIKESORT
            recursive_spikesort(directory);
        else
            fprintf('Session not found.\n')
        end
        return
    end
    
    ntt_files = sort({ntt_files.name});
    
    [save_dir, success] = setup_savedir(directory, config);
    if ~success
        return
    end
    config.save_dir = save_dir;
    
    for k = 1:length(ntt_files)
        filename = ntt_files{k};
        full_filename = fullfile(directory, filename);
        run_spikesort_ntt(full_filename, config);
    end
end