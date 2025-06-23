function [save_dir, success] = setup_savedir(directory, config)
    save_dir = get_savedir(directory, config);
    
    if ~exist(save_dir, 'dir')
        mkdir(save_dir);
    elseif config.FORCE_SPIKESORT
        fprintf('Force. Removing %s.\n', save_dir)
        rmdir(save_dir, 's')
        s = false;
        while ~s
            s = mkdir(save_dir);
            pause(0.5)
        end
    end
    
    if can_write(save_dir)
        success = true;
    else
        fprintf('Do not have permission to write to %s. Skipping.\n', save_dir)
        success = false;
    end
end