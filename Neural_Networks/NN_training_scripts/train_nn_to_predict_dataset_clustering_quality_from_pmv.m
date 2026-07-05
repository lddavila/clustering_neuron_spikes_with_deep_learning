function [] = train_nn_to_predict_dataset_clustering_quality_from_pmv(dir_with_pmv_data,varargin)

%set the path
home_dir = cd("..");
cd("..");
addpath(genpath(fullfile(pwd,"Utility_Functions")));
addpath(genpath(fullfile(pwd,"clustering-master")));
cd(home_dir);

%get a config
config = spikesort_config;

%if the table with data was passed then just use it otherwise get it
if isempty(varargin)
    pmv_table = concatenate_pmv_data_into_table(dir_with_pmv_data);
else
    pmv_table = varargin{1};
end

%set the random seed for repeatable results
rng("default")
disp("Finished setting seed")



end