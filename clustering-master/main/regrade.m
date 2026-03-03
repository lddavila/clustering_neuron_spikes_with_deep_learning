%updated by Luis David Davila and Alexander Friedman
function regrade(the_directory)
%REGRADE Regrades all tetrodes in a directory.
%   REGRADE(directory)
%
%   'directory' is the path to the directory containing tetrodes.

    config = spikesort_config();
    the_directory = regexprep(the_directory, '^~', getenv('HOME'));
    
    ntt_files = dir(fullfile(the_directory, '*.ntt'));
    if isempty(ntt_files)
        if config.RECURSIVE_SPIKESORT
            recursive_spikesort(the_directory);
        else
            fprintf('Session not found.\n')
        end
        return
    end
    
    ntt_files = sort({ntt_files.name});
    
    save_dir = get_savedir(the_directory, config);
    if ~exist(save_dir, 'dir')
        mkdir(save_dir);
    end
    config.save_dir = save_dir;
    
    for k = 1:length(ntt_files)
        filename = ntt_files{k};
        full_filename = fullfile(the_directory, filename);
        regrade_ntt(full_filename, config);
    end
end