function [threshold_probabilities] = get_above_below_probabilities_per_cluster(blind_pass_table)
%get a list of all above/below probabilities
list_of_variables = string(blind_pass_table.Properties.VariableNames);
only_above_below_vars = list_of_variables(contains(list_of_variables,"above_below_"));

%sort above/below threshold vars in ascending order to
%not necessary but I believe it to be more intuitive
split_data = split(only_above_below_vars.',"_");
sorted_thresholds = sort(str2double(split_data(:,end)));

%create an array which will return the values
threshold_probabilities = blind_pass_table{:,strcat("above_below_",string(sorted_thresholds))};
end