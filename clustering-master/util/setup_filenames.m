function filenames = setup_filenames(filename, save_dir)
    [full_dir, basename, ~] = fileparts(filename);
    [~, session_name, ~] = fileparts(full_dir);
    
    filenames = struct();
    basepath = fullfile(save_dir, basename);
    filenames.orig = filename;
    filenames.session_name = session_name;
    filenames.basename = basename;
    filenames.full_dir = full_dir;
    filenames.output = sprintf('%s.mat', basepath);
    filenames.info = sprintf('%s_info.mat', basepath);
    filenames.done = sprintf('%s_done.txt', basepath);
    filenames.stat = sprintf('%s_stat.mat', basepath);
    filenames.ntt = sprintf('%s_clust.ntt', basepath);
    filenames.manual_info = sprintf('%s_manual_info.mat', basepath);
end