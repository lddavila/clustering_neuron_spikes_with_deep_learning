home_dir = cd("..");
cd("..");
root_dir = pwd;
cd(home_dir);
generated_path = genpath(root_dir);
utility_dir = fullfile(root_dir, "Utility_Functions");

% Broad path

addpath(generated_path);

poolobj = gcp("nocreate");
if ~isempty(poolobj)
    delete(poolobj);
end

time_start = tic;
poolobj = parpool;
broad_path_pool_startup = toc(time_start);

delete(poolobj);
rmpath(generated_path);

% Specialized path

addpath(utility_dir);

time_start = tic;
poolobj = parpool;
specialized_path_pool_startup = toc(time_start);

delete(poolobj);
rmpath(utility_dir);

fprintf("Broad path pool startup:       %.2f seconds\n", broad_path_pool_startup);
fprintf("Specialized path pool startup: %.2f seconds\n", specialized_path_pool_startup);