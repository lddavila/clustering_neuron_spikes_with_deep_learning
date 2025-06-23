function recursive_spikesort(directory)
%RECURSIVE_SPIKESORT Co-recursively runs run_spikesort on subdirectories.
%   RECURSIVE_SPIKESORT(directory)
%
%   'directory' is the directory containing subdirectories with NTT files.
%   It is assumed that 'directory' contains no NTT files at the root level.

    all_files = dir(directory);
    folders = all_files([all_files.isdir]);
    folders = sort({folders.name});
    for folder = folders
        name = folder{1};
        if ~isempty(name) && ~strcmp(name(1), '.')
            run_spikesort(fullfile(directory, name))
        end
    end
end