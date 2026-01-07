function [] = get_all_grades_with_padding(blind_pass_table,config)
%this function will be used to ensure that regardless of how many channels
%might be used in a blind pass table we can get a single array that will
%pad any missing values with 0s so that neural network training doesnt fail

all_grades = vertcat(blind_pass_table{:,"grades"}{:});
%first we must get the grades for all the members of the blind pass table


%figure out which grades need to be padded
all_lengths = cellfun(@length, all_grades);
max_grade_length = max(all_lengths,[],1);

%now assemble all remaining grades, padding any ones that are per channel
%with zeros
grade_idxs_to_be_used = config.expanded_grade_idxs;

cell_array = cell(1,length(grade_idxs_to_be_used));
for i=1:length(grade_idxs_to_be_used)
    non_padded_length = cellfun(@length,all_grades(:,grade_idxs_to_be_used(i)));

    %pad any data that doesn't have the max grade size
    arrays_to_pad = find(non_padded_length < max_grade_length(grade_idxs_to_be_used(i)));
    for j=1:length(arrays_to_pad)
        how_many_to_pad =abs( max_grade_length(i)-non_padded_length(arrays_to_pad(j)));
        all_grades{arrays_to_pad(j),grade_idxs_to_be_used(i)} = [all_grades{arrays_to_pad(j),grade_idxs_to_be_used(i)}, zeros(1,how_many_to_pad)];
    end
end
end