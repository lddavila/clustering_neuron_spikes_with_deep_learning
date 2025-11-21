% --- Helper: compute relative folder path (local) ---
function rel_folder = compute_relative_folder(local_dir, base_dir)
    % Ensure both are char for indexing
    local_dir = char(local_dir);
    base_dir  = char(base_dir);

    % Normalize base_dir (remove trailing file separator)
    if endsWith(base_dir, filesep)
        base_dir = base_dir(1:end-1);
    end

    % Default: no relative folder (file directly under base)
    rel_folder = "";

    % If local_dir starts with base_dir, compute remainder
    if strncmp(local_dir, base_dir, numel(base_dir))
        remainder = local_dir(numel(base_dir)+1:end); % may start with filesep
        if startsWith(remainder, filesep)
            remainder = remainder(2:end);
        end
        rel_folder = remainder;
    end
end