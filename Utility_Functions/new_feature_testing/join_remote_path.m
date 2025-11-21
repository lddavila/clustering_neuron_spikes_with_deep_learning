% --- Helper: join components into a POSIX SFTP path ---
function remote_path = join_remote_path(varargin)
    % JOIN_REMOTE_PATH Join components with '/' for SFTP paths.
    %
    % Preserves a leading '/' if the first component has it.

    parts = strings(1, nargin);
    for k = 1:nargin
        p = string(varargin{k});
        p = strtrim(p);
        parts(k) = p;
    end

    % Handle leading slash from first part
    first = parts(1);
    has_leading_slash = startsWith(first, "/");

    % Strip leading/trailing slashes from each part
    for k = 1:numel(parts)
        p = parts(k);
        p = strip(p, "/");
        parts(k) = p;
    end

    % Join with '/'
    remote_path = strjoin(parts(parts ~= ""), "/");

    % Add back global leading slash if needed
    if has_leading_slash
        remote_path = "/" + remote_path;
    end
end