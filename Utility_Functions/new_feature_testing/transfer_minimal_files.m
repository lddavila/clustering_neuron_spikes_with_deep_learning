function transfer_minimal_files(local_base_dir, remote_base_dir, varargin)
%TRANSFER_MINIMAL_FILES
% Copy selected files from local_base_dir into corresponding
% directories under remote_base_dir via SFTP.
%
%   transfer_minimal_files(local_base_dir, remote_base_dir)

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

% --- Connect via SFTP ---
s = sftp(host, user, "Password", pass);
disp('Finished setting up SFTP connection')



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

% Filter to only aligned.mat / blind_pass_table.mat
files_to_transfer = all_entries(any(contains(string(all_entries.name), ["aligned.mat","blind_pass_table.mat"]), 2), :);



num_files = height(files_to_transfer);
fprintf("Found %d files to transfer.\n", num_files);


list_of_files_to_create = string(files_to_transfer.folder);

for i = 1:num_files
    this_row   = files_to_transfer(i, :);
    local_dir  = char(this_row.folder);
    local_name = char(this_row.name);
    local_full = fullfile(local_dir, local_name);

    % Use your Default_Results_Dir anchor
    current_file_to_create = split(list_of_files_to_create(i), filesep);
    place_where_default_starts = find(current_file_to_create == "Default_Results_Dir", 1);

    if isempty(place_where_default_starts)
        warning("Path %s does not contain 'Default_Results_Dir'; skipping.", list_of_files_to_create(i));
        continue;
    end

    % Build remote directory under remote_base_dir (POSIX separators)
    sub_parts   = current_file_to_create(place_where_default_starts+1:end);
    remote_sub  = strjoin(sub_parts, "\");
    remote_dir  = sprintf('%s/%s', remote_base_dir, remote_sub);

    try
        % Just transfer; assume remote_dir already exists
         cd(s, remote_dir);

        % Upload the file into the current remote dir
        mput(s, local_full);
        fprintf("Transferred %d/%d: %s -> %s\n", i, num_files, local_full, remote_dir);
    catch ME
        warning("Failed to transfer %s to %s: %s", local_full, remote_dir, ME.message);
    end
end

% --- Cleanup ---
try
    close(s);
catch
    % ignore
end

fprintf("Transfer complete.\n");
end
