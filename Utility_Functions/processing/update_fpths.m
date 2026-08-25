function blind_pass_table = update_fpths(blind_pass_table, config)
%UPDATE_FPTHS Update stored paths to use the current machine's base path.
%
% The portion of each path through
% config.BLIND_PASS_DIR_PRECOMPUTED_ONLY_END is replaced by
% config.BLIND_PASS_DIR_PRECOMPUTED.
%
% Both Windows "\" and Unix "/" source paths are supported.

file_path_names = [
    "fp_to_aligned"
    "fp_to_cleaned_clusters"
    "fp_to_reg_timestamps"
    "fp_to_reg_timestamps_of_the_spikes"
    "fp_to_sorted_spike_windows_after_purges"
    "fp_to_timestamps_rtvals"
];

new_base_path = string(config.BLIND_PASS_DIR_PRECOMPUTED);
boundary_folder = string(config.BLIND_PASS_DIR_PRECOMPUTED_ONLY_END);

% Normalize the configured base path for the current operating system.
new_base_path = replace(new_base_path, "/", filesep);
new_base_path = replace(new_base_path, "\", filesep);

% Confirm that all expected columns exist.
table_columns = string(blind_pass_table.Properties.VariableNames);
missing_columns = file_path_names(~ismember(file_path_names, table_columns));

if ~isempty(missing_columns)
    error( ...
        "update_fpths:MissingColumns", ...
        "The following path columns are missing: %s", ...
        char(strjoin(missing_columns, ", ")) ...
    );
end

for column_index = 1:numel(file_path_names)
    column_name = char(file_path_names(column_index));
    original_column = blind_pass_table.(column_name);
    updated_column = string(original_column);

    for row_index = 1:numel(updated_column)
        current_path = updated_column(row_index);

        % Leave empty or missing paths unchanged.
        if ismissing(current_path) || strlength(current_path) == 0
            continue;
        end

        % Use "/" temporarily so paths from either OS can be processed.
        normalized_path = replace(current_path, "\", "/");
        path_parts = split(normalized_path, "/");

        % Absolute Unix paths produce an empty first element.
        path_parts(path_parts == "") = [];

        % Match the boundary as a complete folder name.
        boundary_index = find( ...
            strcmpi(path_parts, boundary_folder), ...
            1, ...
            "first" ...
        );

        if isempty(boundary_index)
            error( ...
                "update_fpths:BoundaryNotFound", ...
                ["Could not find boundary folder '%s' in row %d of " ...
                 "column '%s'. Path: %s"], ...
                char(boundary_folder), ...
                row_index, ...
                column_name, ...
                char(current_path) ...
            );
        end

        % Preserve everything following the boundary folder.
        remaining_parts = path_parts(boundary_index + 1:end);

        if isempty(remaining_parts)
            updated_column(row_index) = new_base_path;
        else
            relative_path = strjoin(remaining_parts, filesep);
            updated_column(row_index) = fullfile( ...
                new_base_path, ...
                relative_path ...
            );
        end
    end

    % Preserve the original table column's common data type.
    if iscell(original_column)
        blind_pass_table.(column_name) = cellstr(updated_column);
    elseif isstring(original_column)
        blind_pass_table.(column_name) = updated_column;
    elseif ischar(original_column)
        blind_pass_table.(column_name) = char(updated_column);
    else
        error( ...
            "update_fpths:UnsupportedColumnType", ...
            "Column '%s' must contain character vectors or strings.", ...
            column_name ...
        );
    end
end

end