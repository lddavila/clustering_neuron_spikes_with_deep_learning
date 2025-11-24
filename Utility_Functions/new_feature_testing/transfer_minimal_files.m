function transfer_minimal_files(local_base_dir, remote_base_dir, varargin)
    %TRANSFER_MINIMAL_FILES
    % Rebuild local directory structure under remote_base_dir on SFTP host
    % and copy all files into their corresponding directories.
    %
    %   transfer_minimal_files(local_base_dir, remote_base_dir)
    %
    % Example:
    %   local_base  = "/scratch/lddavila/data_for_figures";
    %   remote_base = "/G/david_spikesorting_paper_data/OneDrive - The University of Texas at El Paso/Cluster Images Sorted into 5 accuracy categories/data_to_reference_for_figures";
    %   transfer_minimal_files(local_base, remote_base);

    % --- Optional: add paths the way you had it ---
    home_dir = cd("..");
    cd("..");
    addpath(genpath(pwd));
    cd(home_dir)
    disp("Finished adding path")

    % --- Read secrets from environment or varargin ---
    if isempty(varargin)
        host = getenv("SFTP_HOST");
        user = getenv("SFTP_USER");
        pass = getenv("SFTP_PASS");
    else
        host = varargin{1};
        user = varargin{2};
        pass = varargin{3};
    end
    disp("Finished getting host/password/user")

    if isempty(host) || isempty(user) || isempty(pass)
        error("SFTP_HOST, SFTP_USER, and SFTP_PASS must be set (or passed in).");
    end

    fprintf("Connecting to %s as %s...\n", host, user);

    % --- Discover local files recursively ---
    listing = dir(fullfile(local_base_dir, "**", "*"));
    disp("Finished getting files");

    all_entries = struct2table(listing);

    % Remove '.' and '..'
    name_str = string(all_entries.name);
    all_entries(name_str == "." | name_str == "..", :) = [];
    disp("Finished filtering.");

    % Keep only files
    all_entries = all_entries(~all_entries.isdir, :);

    % If you really want ALL files, don't filter by name:
    files_to_transfer = all_entries;

    if isempty(files_to_transfer)
        fprintf("No files found under %s\n", local_base_dir);
        return;
    end

    num_files = height(files_to_transfer);
    fprintf("Found %d files to transfer.\n", num_files);

    % --- Connect via SFTP ---
    s = sftp(host, user, "Password", pass);
    disp('Finished setting up connection')

    try
        curpwd = pwd(s);
        fprintf("Remote initial directory: %s\n", curpwd);
    catch
        % ignore
    end

    % --- Upload loop with progress bar (optional) ---
    q = parallel.pool.DataQueue;
    afterEach(q, @print_status_bar)
    print_status_bar(num_files, "transfer_minimal_files.m")

    for i = 2:2.5%num_files
        this_row   = files_to_transfer(i, :);
        local_dir  = char(this_row.folder);
        local_name = char(this_row.name);
        local_full = fullfile(local_dir, local_name);

        % Relative folder w.r.t. local_base_dir
        rel_folder = compute_relative_folder(local_dir, local_base_dir);

        % Convert to POSIX separators for remote path
        rel_folder_remote = strrep(rel_folder, filesep, '/');

        % Build full remote directory path
        if isempty(rel_folder_remote)
            remote_dir = remote_base_dir;
        else
            remote_dir = join_remote_path(remote_base_dir, rel_folder_remote);
        end

        fprintf("[%d/%d] %s\n", i, num_files, local_full);
        fprintf("       -> %s\n", remote_dir);

        % Ensure the full remote directory chain exists
        ok = ensure_remote_dir(s, remote_dir);
        if ~ok
            warning("Skipping file because remote directory could not be created: %s", remote_dir);
            continue;
        end

        % cd into remote dir and upload file
        try
            cd(s, remote_dir);
            mput(s, local_full);
        catch ME
            warning("Failed to transfer %s to %s: %s", local_full, remote_dir, ME.message);
        end

        send(q, []);
    end

    % --- Cleanup ---
    try
        close(s);
    catch
        % ignore
    end

    fprintf("Transfer complete.\n");
end