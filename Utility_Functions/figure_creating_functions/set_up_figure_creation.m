function [config,figure_dir] = set_up_figure_creation(options)
arguments
    options.name_of_calling_file = ""
end
home_dir = cd(".."); 
cd("..");
addpath(genpath(fullfile(pwd,"Neural_Networks/"))); 
addpath(genpath(fullfile(pwd,"Grading_scripts")));
addpath(genpath(fullfile(pwd,"clustering-master")));
addpath(genpath(fullfile(pwd,"Utility_Functions")));
cd(home_dir);
config = spikesort_config();
figure_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"poster_figs"));
if ~(options.name_of_calling_file=="")
    figure_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(figure_dir,strrep(options.name_of_calling_file,".m","")));
end
end