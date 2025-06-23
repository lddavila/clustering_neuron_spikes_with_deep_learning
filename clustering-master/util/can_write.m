function s = can_write(save_dir)
    tempfolder = fullfile(save_dir, 'TESTTEST');
    s = mkdir(tempfolder);
    if s
        rmdir(tempfolder)
    end
end