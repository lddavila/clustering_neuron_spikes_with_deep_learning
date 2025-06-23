function output = prepare_manual_output(manual_clustered, filenames)
%PREPARE_MANUAL_OUTPUT Prepares manually clustered .mat files so that
%future functions can work with a standardized structure.
%   output = PREPARE_MANUAL_OUTPUT(manual_clustered, basename)
%
%   'manual_clustered' is the directory where manually clustered .mat files
%   should live (if they exist).
%
%   'basename' is the filename of the NTT file without the .ntt extention.
%   Future work: generalize this process so that the user can create a
%   function which will correspond the NTT file with manually clustered
%   .mat files correctly. This is needed because everyone seems to have
%   different conventions for saving their clustered data.
%
%   'output' is the standardized output to be used in future functions. If
%   it is not [] by the time the function call is over:
%   - the first column contains the timestamps of the spikes in seconds
%   - the second column contains the cluster classification of the spikes
%       E.g., a value of '3' means that the spike belongs to cluster 3.

    is_manual_clustered = exist(manual_clustered, 'dir');

    output = [];
    
    if is_manual_clustered
        % First get a list of the .mat files that could correspond the NTT
        % file.
        
        ttnum_r = regexp(lower(filenames.basename), '\d+', 'match');
        ttnum = str2double(ttnum_r);
        
        % KYLE FORMAT:
%         format_str = sprintf('%s_%03d*.mat', filenames.session_name, ttnum-1);
        % LEDIA_FORMAT:
%         format_str = sprintf('*_%03d*.mat', ttnum - 1);
        % KATY FORMAT:
%         format_str = sprintf('*_%02d.mat', ttnum);
        % ALEXANDER FORMAT:
        format_str = sprintf('%s*.mat', filenames.basename);
        
        mat_files = dir(fullfile(manual_clustered, format_str));
        manual_output = [];
        
        % If the number of such corresponding files is exactly 1, that's
        % the one. Otherwise, choose the one that matches best.
        if isscalar(mat_files)
            clustered = load(fullfile(manual_clustered, mat_files.name));
        else
            clustered = [];
            for l = 1:length(mat_files)
                f = mat_files(l);
                if strcmp(f.name, sprintf('%s.mat', lower(filenames.basename)))
                    clustered = load(fullfile(manual_clustered, f.name));
                    break
                end
            end
        end
        
        % If we have found a matching .mat file, 'clustered' shouldn't be
        % empty, so get the data in the .mat file.
        % TODO: Maybe move this into the for loop above...? Maybe not.
        if ~isempty(clustered)
            field_name = fields(clustered);
            if isscalar(field_name)
                manual_output = clustered.(field_name{1});
            end
        end
        
        if ~isempty(manual_output)
            timestamp_col = [];
            cluster_col = [];
            
            % Find the timestamp column and the cluster column in the
            % output matrix.
            
            for k = 1:size(manual_output, 2)
                col = manual_output(:, k);
                if all(col >= 0)
                    ucol = unique(col);
                    if isscalar(ucol) || min(diff(ucol)) == 1
                        if isempty(cluster_col) || max(cluster_col) < max(ucol)
                            cluster_col = col;
                        end
                    elseif all(diff(col) >= 0) && isempty(timestamp_col)
                        timestamp_col = col;
                    end
                end
            end
            
            % Only if we find those columns can we make our final output
            % matrix.
            if ~isempty(timestamp_col) && ~isempty(cluster_col)
                output = [timestamp_col cluster_col];
            end
        end
    end
end