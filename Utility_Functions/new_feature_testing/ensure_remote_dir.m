% --- Helper: recursively ensure remote directory exists ---
function ok = ensure_remote_dir(s, dirpath)
    % ENSURE_REMOTE_DIR Recursively create directories on remote SFTP server.
    % dirpath is POSIX-style (e.g. "/G/.../data_to_reference_for_figures")

    ok = true;

    p = string(dirpath);
    p = strtrim(p);
    if p == ""
        return;
    end

    has_leading_slash = startsWith(p, "/");
    p = strip(p, "/");
    parts = split(p, "/");

    % Start from root ("/") or current dir
    if has_leading_slash
        current = "/";
    else
        current = "";
    end

    for i = 1:numel(parts)
        part = parts(i);
        if part == ""
            continue;
        end

        if current == "/" || current == ""
            next_dir = "/" + part;
        else
            next_dir = current + "/" + part;
        end

        try
            cd(s, next_dir);  % try to enter
        catch
            try
                mkdir(s, next_dir);
                cd(s, next_dir);
            catch ME
                warning("Could not create remote dir %s: %s", next_dir, ME.message);
                ok = false;
                return;
            end
        end

        current = next_dir;
    end
end