function [padded_grades] = get_all_grades_with_padding(blind_pass_table,config)
%this function will be used to ensure that regardless of how many channels
%might be used in a blind pass table we can get a single array that will
%pad any missing values with 0s so that neural network training doesnt fail

all_grades = vertcat(blind_pass_table{:,"grades"}{:});
%first we must get the grades for all the members of the blind pass table

%transpose any grades that are nx1 and not 1xn
for i=1:size(all_grades,2)
    sizes_of_all_grades = cell2mat(cellfun(@size,all_grades(:,i),'UniformOutput',false));
    grades_to_transpose = find(sizes_of_all_grades(:,1) > sizes_of_all_grades(:,2));
    for j=1:length(grades_to_transpose)
        all_grades{j,i} = all_grades{j,i}.';
    end
end

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
        % fprintf("i:%i j:%i\n",i,j);
       
        how_many_to_pad =abs( max_grade_length(grade_idxs_to_be_used(i))-non_padded_length(arrays_to_pad(j)));

        
        % disp("How many to pad")
        % disp(how_many_to_pad)
        % disp("data to be padded")
        % disp(all_grades{arrays_to_pad(j),grade_idxs_to_be_used(i)});
        % disp("Padding array")
        % disp(zeros(1,how_many_to_pad))
        all_grades{arrays_to_pad(j),grade_idxs_to_be_used(i)} = [all_grades{arrays_to_pad(j),grade_idxs_to_be_used(i)}, zeros(1,how_many_to_pad)];
        
    end
    %the conditional below is to account for a strange edge case where when
    %the values are only 0-1 and strangely matlab cast some of those as
    %logical and some as doubles so we cast them all as doubles manually
    if i==7
        cell_array{i} = double(vertcat(all_grades{:,grade_idxs_to_be_used(i)}));
    else
        cell_array{i} = cell2mat( cellfun(@double, all_grades(:,grade_idxs_to_be_used(i)), 'UniformOutput', false));
    end
    
end
padded_grades = horzcat(cell_array{:});
end