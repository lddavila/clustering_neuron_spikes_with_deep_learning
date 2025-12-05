function [] = train_nn_to_identify_clusters_based_on_image(varargin)
%we'll train this neural network to try to filter out any tetrode whose
%images show no clusters


[dir,name,ext] = fileparts(mfilename('fullpath'));
cd(dir);
home_dir = cd("..");
cd("..");
addpath(genpath(pwd))
cd(home_dir)
disp("Finished adding path");

%get the config
config = spikesort_config();
disp("Finished getting config");

%create a directory to save the results to
dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"test_image_recognition_idea"));
sub_image_directory = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_results_to,"image_dir"));
disp("Finished creating save dir");

%import the blind pass data we will use for trainining
if length(varargin)<1
    blind_pass_table = importdata(config.FP_TO_6_to_10);
else
    blind_pass_table = varargin{1};
end
disp("Finshed loading blind pass directory");

%add an og idx feature to keep track of them after slicing
blind_pass_table.og_idx = (1:size(blind_pass_table,1)).';

%update fpth to local
blind_pass_table = update_fpths(blind_pass_table,config);
disp("finished updating fpths")

%we'll create 2 folders in the sub image directory
%has_cluster
%doesnt_have_cluster
has_cluster = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(sub_image_directory,"has_cluster"));
doesnt_have_cluster = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(sub_image_directory,"doesnt_have_cluster"));

%the first condition is to select only the rows in blind pass table which
%have less then 1% accuracy
c1 = blind_pass_table{:,"accuracy"}<1;

%the second filter is to exclude the rows specified in c1 which also have a
%cluster on the same tetrode,recording, and z score as we want to see which
%of these
sub_c2 = blind_pass_table{:,"accuracy"}>50;

%get a string which represents the tetrode/z score/recording name for every
%row specified by condition 1
%this is a group key
in_c1 = blind_pass_table{c1,"Tetrode"} +"_"+ string(blind_pass_table{c1,"Z Score"})+"_" +blind_pass_table{c1,"recording_name"};
outside_c1 = blind_pass_table{sub_c2,"Tetrode"} +"_"+ string(blind_pass_table{sub_c2,"Z Score"})+"_" +blind_pass_table{sub_c2,"recording_name"};

%condition 2 adds an extra filter ensuring that tetrodes exclusively have
%clusters less than 1% accuracy
c2 = ~ismember(in_c1,outside_c1);

%find tetrodes where everything found on them was just MUA i.e. no clusters
%greater than 50% accuracy were found on them
only_bad_results = blind_pass_table(c1,:);
only_bad_results = only_bad_results(c2,:);

only_good_results = blind_pass_table(setdiff(1:size(blind_pass_table,1),only_bad_results.og_idx),:);


%now we'll create the images and sort them into their appropriate folder
%based on accuracy

sliced_only_good = slice_table_for_parallel_processing(only_good_results,["Z Score","Tetrode","recording_name"]);
disp("Finsihed slicing good")
sliced_only_bad = slice_table_for_parallel_processing(only_bad_results,["Z Score","Tetrode","recording_name"]);
disp("finished slicing bad")

q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = length(sliced_only_bad);
print_status_bar(num_iterations,"getting_bad_images.m")
parfor i=1:length(sliced_only_bad)
    % try
        current_data = sliced_only_bad{i};
        current_image_name = "z_score_"+current_data{1,"Z Score"}+"_tetrode_"+current_data{1,"Tetrode"}+"_"+current_data{1,"recording_name"}+".png";
        current_image_name = fullfile(doesnt_have_cluster,current_image_name);
        if isfile(current_image_name)
            send(q,[]);
            continue;
        end
        current_channels = current_data{1,"grades"}{1}{49};
        current_aligned = importdata(current_data{1,"fp_to_aligned"});
        current_aligned = current_aligned.aligned;
        current_image = produce_nth_dimensional_view(current_aligned,current_channels);
        imwrite(current_image,current_image_name)
        send(q,[]);
    % catch
    %     send(q,[]);
    % end
end
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = length(sliced_only_good);
print_status_bar(num_iterations,"getting_good_images.m")
parfor i=1:length(sliced_only_good)
    % try
        current_data = sliced_only_good{i};
        current_image_name = "z_score_"+current_data{1,"Z Score"}+"_tetrode_"+current_data{1,"Tetrode"}+"_"+current_data{1,"recording_name"}+".png";
        current_image_name = fullfile(has_cluster,current_image_name);
        if isfile(current_image_name)
            send(q,[]);
            continue;
        end
        current_channels = current_data{1,"grades"}{1}{49};
        current_aligned = importdata(current_data{1,"fp_to_aligned"});
        current_aligned = current_aligned.aligned;
        current_image = produce_nth_dimensional_view(current_aligned,current_channels);
        imwrite(current_image,current_image_name)
        send(q,[]);
    % catch
    %     send(q,[]);
    % end
end


end