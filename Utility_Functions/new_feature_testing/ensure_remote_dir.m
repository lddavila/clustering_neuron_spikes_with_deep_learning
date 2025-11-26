function ok = ensure_remote_dir(s, remote_dir)
    ok = false;
    try
        remote_dir = char(remote_dir);
        remote_dir = strrep(remote_dir, '\', '/');

        parts = split(remote_dir, '/');

        % Build path segment by segment
        path = "";
        for k = 1:numel(parts)
            part = parts{k};
            if part == ""
                % Handle a leading "/" (absolute path)
                path = "/";
                continue;
            end

            if path == "/" || path == ""
                path = [path part];
            else
                path = [path '/' part];
            end

            % Try to cd into this level; mkdir if it doesn't exist
            try
                cd(s, path);
            catch
                try
                    mkdir(s, path);
                    cd(s, path);
                catch ME
                    warning("Failed to ensure remote folder '%s': %s", path, ME.message);
                    return;
                end
            end
        end

        ok = true;
    catch ME
        warning("ensure_remote_dir failed for %s: %s", remote_dir, ME.message);
    end
end