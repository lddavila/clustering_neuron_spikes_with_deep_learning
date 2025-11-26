function rel_folder = compute_relative_folder(local_dir, local_base_dir)
    local_dir      = char(local_dir);
    local_base_dir = char(local_base_dir);

    % Normalize separators to platform separator for comparison
    local_dir      = strrep(local_dir, '\', filesep);
    local_base_dir = strrep(local_base_dir, '\', filesep);

    if ~startsWith(local_dir, local_base_dir)
        error("Local dir '%s' is not under base '%s'.", local_dir, local_base_dir);
    end

    rel_folder = local_dir(numel(local_base_dir)+1:end);  % strip base
    if startsWith(rel_folder, filesep)
        rel_folder(1) = [];  % drop leading separator
    end
end