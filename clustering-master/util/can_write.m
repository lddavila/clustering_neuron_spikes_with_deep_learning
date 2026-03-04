%edited by Luis David Davila and Alexander Friedman
function the_s = can_write(the_save_dir)
    tempfolder = fullfile(the_save_dir, 'TESTTEST');
    the_s = mkdir(tempfolder);
    if the_s
        rmdir(tempfolder)
    end
end