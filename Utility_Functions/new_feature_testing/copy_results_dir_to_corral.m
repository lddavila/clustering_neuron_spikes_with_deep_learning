function [] = copy_results_dir_to_corral(results_dir,corral_dir)
home_dir = cd("..");
cd("..");


addpath(genpath(fullfile(pwd,"Neural_Networks/"))); 
addpath(genpath(fullfile(pwd,"Grading_scripts")));
addpath(genpath(fullfile(pwd,"clustering-master")));
addpath(genpath(fullfile(pwd,"Utility_Functions")));
cd(home_dir);

config = spikesort_config();

base_path = config.parent_save_dir;

dir_on_corral = fullfile(corral_dir,"results_dir");
mkdir(dir_on_corral)

all_files_to_copy = struct2table(dir(fullfile(results_dir,'**', '*')));
all_files_to_copy.folder = string(all_files_to_copy.folder);
all_files_to_copy.name = string(all_files_to_copy.name);

to_be_removed = all_files_to_copy.name == "." | all_files_to_copy.name == "..";

all_files_to_copy(to_be_removed,:) = [];

%first copy the directory structure to ensure it is maintained
only_directories = all_files_to_copy(all_files_to_copy{:,"isdir"} == true,:);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = height(only_directories);
print_status_bar(num_iterations,"copy_results_dir_to_corral | copying directory structure.m")
parfor i=1:height(only_directories)
    new_fn = fullfile(strrep(only_directories{i,"folder"},base_path,dir_on_corral),only_directories{i,"name"});
    if ~isfolder(new_fn)
        mkdir(new_fn)
    end
	send(q,[])
end

%now copy the actual files
only_files = all_files_to_copy(all_files_to_copy{:,"isdir"} == false,:);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = height(only_files);
print_status_bar(num_iterations,"copy_results_dir_to_corral | copying actual_files.m")
parfor i=1:height(only_files)
    new_fn = fullfile(strrep(only_files{i,"folder"},base_path,dir_on_corral),only_files{i,"name"});
    og_name = fullfile(only_files{i,"folder"},only_files{i,"name"});
    if ~isfile(new_fn)
        copyfile(og_name,new_fn);
    end
	send(q,[])
end

end