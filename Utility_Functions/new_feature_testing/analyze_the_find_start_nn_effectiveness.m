function [] = analyze_the_find_start_nn_effectiveness(varargin)
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));

%import the blind pass data we will use for trainining
if length(varargin)<1
    blind_pass_table = importdata(config.FP_TO_6_to_10);
else
    blind_pass_table = varargin{1};
end
disp("Finshed loading blind pass directory");

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

%find tetrodes where everything found on them was just MUA
only_bad_results = blind_pass_table(c1,:);
only_bad_results = only_bad_results(c2,:);
only_bad_results = sortrows(only_bad_results,["Z Score","Tetrode","recording_name"]);

%now that we have a case of truly only bad cases let's see how many would
%have been filtered out if we find_start neural network

for i=1:height(only_bad_results)
    get_clust
end
end