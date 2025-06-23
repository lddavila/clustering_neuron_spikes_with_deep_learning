function save_dir = get_savedir(directory, config)
%GET_SAVEDIR Returns the directory in which to save the output.
    if isempty(config.SAVE_DIRECTORY)
        save_dir = fullfile(directory, 'Results');
    else
        [restpath, sess_name, ~] = fileparts(directory);
        [restpath, s_name, ~] = fileparts(restpath);
        [restpath, t_name, ~] = fileparts(restpath);
        [~, top_name, ~] = fileparts(restpath);
        save_dir = fullfile(config.SAVE_DIRECTORY, fullfile(top_name, t_name, s_name, sess_name));
    end
end