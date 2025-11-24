function [valleys] = get_cv_of_valley_feature_of_nn(blind_pass_table,feature_string)
valleys = [];
split_feature = split(feature_string,"_");
which_valley = split_feature(2);
all_grades = vertcat(blind_pass_table{:,"grades"}{:});
if which_valley=="1"
    valleys = horzcat(all_grades{:,65}).';
elseif which_valley=="2"
    valleys = horzcat(all_grades{:,66}).';
else
    error("can only have valley_1 or valley_2");
end
end