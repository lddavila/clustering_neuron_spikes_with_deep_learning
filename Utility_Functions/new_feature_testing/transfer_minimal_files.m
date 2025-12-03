function transfer_minimal_files(local_base_dir, remote_base_dir, varargin)
%TRANSFER_MINIMAL_FILES
% Copy selected files from local_base_dir into corresponding
% directories under remote_base_dir via SFTP.
%
%   transfer_minimal_files(local_base_dir, remote_base_dir)
%
% remote_base_dir can be either:
%   - Windows style: "G:\david_spikesorting_paper_data\..."; or
%   - POSIX style:   "/G/david_spikesorting_paper_data/..."

    % Optional: add project paths (your original pattern)
    home_dir = cd("..");
    cd("..");
    addpath(genpath(pwd));
    cd(home_dir)
    disp("Finished adding path")

    % Read secrets from environment or varargin
    if isempty(varargin)
        host = getenv("SFTP_HOST");
        user = getenv("SFTP_USER");
        pass = getenv("SFTP_PASS");
    else
        host = varargin{1};
        user = varargin{2};
        pass = varargin{3};
    end
    disp("Finished getting host/user/pass")

    if isempty(host) || isempty(user) || isempty(pass)
        error("SFTP_HOST, SFTP_USER, and SFTP_PASS must be set (or passed in).");
    end

    fprintf("Connecting to %s as %s...\n", host, user);

    % Connect via SFTP
    s = sftp(host, user, "Password", pass);
    disp("Finished setting up SFTP connection")

    % Normalize remote_base_dir for SFTP (POSIX-style)
    remote_root = char(remote_base_dir);
    remote_root = strrep(remote_root, '\', '/');           % backslash -> slash

    % Convert "G:/foo/bar" -> "/G/foo/bar" if needed
    driveMatch = regexp(remote_root, '^([A-Za-z]):/(.*)$', 'tokens', 'once');
    if ~isempty(driveMatch)
        driveLetter = upper(driveMatch{1});
        pathRest    = driveMatch{2};
        remote_root = ['/', driveLetter, '/', pathRest];
    end

    % Remove trailing slash (except if root is just "/")
    if numel(remote_root) > 1 && remote_root(end) == '/'
        remote_root(end) = [];
    end

    fprintf("Remote base dir (SFTP view): %s\n", remote_root);

    % Discover local files recursively
    listing = dir(fullfile(local_base_dir, "**", "*"));
    disp("Finished getting files")

    all_entries = struct2table(listing);

    % Remove '.' and '..'
    name_str = string(all_entries.name);
    all_entries(name_str == "." | name_str == "..", :) = [];
    disp("Finished filtering.")

    % Keep only files
    all_entries = all_entries(~all_entries.isdir, :);

    % Filter to only aligned.mat / blind_pass_table.mat
    files_to_transfer = all_entries( ...
        any(contains(string(all_entries.name), ["aligned.mat","blind_pass_table.mat"]), 2), :);

    if isempty(files_to_transfer)
        fprintf("No matching files found under %s\n", local_base_dir);
        try
            close(s); 
        catch
        end
        return;
    end

    num_files = height(files_to_transfer);
    fprintf("Found %d files to transfer.\n", num_files);

    list_of_files_to_create = string(files_to_transfer.folder);

    % Upload loop
    for i = 1:num_files
        this_row   = files_to_transfer(i, :);
        local_dir  = char(this_row.folder);
        local_name = char(this_row.name);
        local_full = fullfile(local_dir, local_name);

        % Split local folder and anchor at "Default_Results_Dir"
        current_file_to_create = split(list_of_files_to_create(i), filesep);
        place_where_default_starts = find(current_file_to_create == "Default_Results_Dir", 1);

        if isempty(place_where_default_starts)
            warning("Path %s does not contain 'Default_Results_Dir'; skipping.", ...
                list_of_files_to_create(i));
            continue;
        end

        % Everything after "Default_Results_Dir" becomes the remote sub-path
        sub_parts  = current_file_to_create(place_where_default_starts+1:end);
        remote_sub = strjoin(sub_parts, "/");   % POSIX separators

        if strlength(remote_sub) == 0
            remote_dir = string(remote_root);
        else
            remote_dir = string(remote_root) + "/" + remote_sub;
        end

        try
            % Change remote working directory
            cd(s, char(remote_dir));

            % For debugging:
            % fprintf("CD to remote: %s\n", remote_dir);

            % Upload the file into current remote dir
            disp("File about to be transferred:")
            disp(local_full)
            disp("Remote location:")
            disp(remote_dir)

            mput(s, local_full);

            fprintf("Transferred %d/%d: %s -> %s\n", ...
                i, num_files, local_full, remote_dir);

        catch ME
            warning("Failed to transfer %s to %s: %s", ...
                local_full, remote_dir, ME.message);
        end
    end

    % Cleanup
    try
        close(s);
    catch
    end

    fprintf("Transfer complete.\n");
end
