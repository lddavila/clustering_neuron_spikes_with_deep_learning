%edited by Luis David Davila and Alexander Friedman
function the_save_dir = get_savedir(the_directory, the_config)
%GET_SAVEDIR Returns the directory in which to save the output.
    if isempty(the_config.SAVE_DIRECTORY)
        the_save_dir = fullfile(the_directory, 'Results');
    else
        [restpath, sess_name, ~] = fileparts(the_directory);
        [restpath, s_name, ~] = fileparts(restpath);
        [restpath, t_name, ~] = fileparts(restpath);
        [~, top_name, ~] = fileparts(restpath);
        the_save_dir = fullfile(the_config.SAVE_DIRECTORY, fullfile(top_name, t_name, s_name, sess_name));
    end
end