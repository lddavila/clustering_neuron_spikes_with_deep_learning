%edited by Luis David Davila and Alexander Friedman
function the_filenames = setup_filenames(the_filename, the_save_dir)
    [full_dir, basename, ~] = fileparts(the_filename);
    [~, session_name, ~] = fileparts(full_dir);
    
    the_filenames = struct();
    basepath = fullfile(the_save_dir, basename);
    the_filenames.orig = the_filename;
    the_filenames.session_name = session_name;
    the_filenames.basename = basename;
    the_filenames.full_dir = full_dir;
    the_filenames.output = sprintf('%s.mat', basepath);
    the_filenames.info = sprintf('%s_info.mat', basepath);
    the_filenames.done = sprintf('%s_done.txt', basepath);
    the_filenames.stat = sprintf('%s_stat.mat', basepath);
    the_filenames.ntt = sprintf('%s_clust.ntt', basepath);
    the_filenames.manual_info = sprintf('%s_manual_info.mat', basepath);
end