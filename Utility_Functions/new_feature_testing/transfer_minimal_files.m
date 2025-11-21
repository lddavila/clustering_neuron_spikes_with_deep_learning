function transfer_minimal_files(local_base_dir, remote_base_dir,varargin)
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir)
disp("Finished adding path")
%TRANSFER_MINIMAL_FILES
%   Transfer only selected files from a local directory tree on the cluster
%   to a remote Windows machine via SFTP, preserving relative structure.
%
%   transfer_minimal_files(local_base_dir, remote_base_dir)
%
%   Inputs:
%       local_base_dir  - Local base directory on the cluster (Linux path),
%                        e.g. "/scratch/lddavila/exp1"
%
%       remote_base_dir - Remote base directory as an SFTP path, POSIX-style,
%                        e.g. "/G/david_spikesorting_paper_data/OneDrive - The University of Texas at El Paso/Cluster Images Sorted into 5 accuracy categories/data_to_reference_for_figures"
%
%   Secrets:
%       Reads connection info from environment variables:
%           SFTP_HOST  - hostname or IP of the Windows machine
%           SFTP_USER  - username for SFTP login
%           SFTP_PASS  - password for SFTP login
%
%   Example:
%       local_base  = "/scratch/lddavila/data_for_figures";
%       remote_base = "/G/david_spikesorting_paper_data/OneDrive - The University of Texas at El Paso/Cluster Images Sorted into 5 accuracy categories/data_to_reference_for_figures";
%       transfer_minimal_files(local_base, remote_base);

% --- Read secrets from environment (no secrets in Git) ---
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
    error("SFTP_HOST, SFTP_USER, and SFTP_PASS must be set in the environment.");
end

fprintf("Connecting to %s as %s...\n", host, user);

% --- Discover local files recursively ---
% Get all files and subfolders under local_base_dir
listing = dir(fullfile(local_base_dir, "**", "*"));
disp("Finished getting files");
% Convert to table for easier filtering
all_entries = struct2table(listing);

% Remove '.' and '..'
name_str = string(all_entries.name);
all_entries(name_str == "." | name_str == "..", :) = [];
disp("Finished filtering.")
% Keep only files (no directories)
all_entries = all_entries(~all_entries.isdir, :);

% Filenames we care about
eligible_names = ["blind_pass_table.mat", "aligned.mat"];

is_eligible = any(contains(string(all_entries.name), eligible_names), 2);
files_to_transfer = all_entries(is_eligible, :);

if isempty(files_to_transfer)
    fprintf("No eligible files found under %s\n", local_base_dir);
    return;
end

num_files = height(files_to_transfer);
fprintf("Found %d eligible files to transfer.\n", num_files);

% --- Connect via SFTP ---
s = sftp(host, user, "Password", pass);
disp('Finsihed setting up connection')
% (Optional) show remote working dir
try
    curpwd = pwd(s);
    fprintf("Remote initial directory: %s\n", curpwd);
catch
    % ignore
end

% --- Upload loop ---
%create a dataqueue to track prograss
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
print_status_bar(num_files,"transfer_minimal_files.m")

for i = 1:1.5%num_files
    this_row   = files_to_transfer(i, :);
    local_dir  = char(this_row.folder);  % local folder (Linux)
    local_name = char(this_row.name);    % filename
    local_full = fullfile(local_dir, local_name);

    % Compute relative directory part w.r.t local_base_dir
    rel_folder = compute_relative_folder(local_dir, local_base_dir);

    % Convert local separators to remote POSIX separators
    rel_folder_remote = strrep(rel_folder, filesep, '/');

    % Build full remote directory path under remote_base_dir
    if isempty(rel_folder_remote)
        remote_dir = remote_base_dir;   % directly under base
    else
        remote_dir = join_remote_path(remote_base_dir, rel_folder_remote);
    end

    fprintf("[%d/%d] %s\n", i, num_files, local_full);
    fprintf("       -> %s\n", remote_dir);

    % Ensure the remote directory exists
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
    send(q,[])
end

% --- Cleanup ---
try
    close(s);
catch
    % ignore
end

fprintf("Transfer complete.\n");
end