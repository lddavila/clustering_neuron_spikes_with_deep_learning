function [padded_grades,old_to_new_cell_array] = get_all_grades_with_padding(blind_pass_table,config,options)
%this function will be used to ensure that regardless of how many channels
%might be used in a blind pass table we can get a single array that will
%pad any missing values with 0s so that neural network training doesnt fail
arguments
    blind_pass_table table                 %required
    config struct               %required
    options.is_split logical = false % Optional named argument
    options.predefined_old_to_new_cell_array = {};
end
%old_to_new_cell_array
%nx3 cell array
%col 1 = original grade idx
%col 2 = which for loop assigned the data
%col 3 = the index where the original grade will appear in padded_grades

%first we must get the grades for all the members of the blind pass table
if options.is_split
    all_grades = vertcat(blind_pass_table{:,"grades"});
else
    all_grades = vertcat(blind_pass_table{:,"grades"}{:});
end


%transpose any grades that are nx1 and not 1xn
for i=1:size(all_grades,2)
    sizes_of_all_grades = cell2mat(cellfun(@size,all_grades(:,i),'UniformOutput',false));
    grades_to_transpose = find(sizes_of_all_grades(:,1) > sizes_of_all_grades(:,2));
    for j=1:length(grades_to_transpose)
        row_idx = grades_to_transpose(j);
        all_grades{row_idx,i} = all_grades{row_idx,i}.';
    end
end

%in the case for when we want to take some data (say a 2 channel data
%set) and pad it to match the expected data set ( which might be a
%3,4,...,n channel dataset)
%it could also be used for the opposite direction, but I don't forsee that
%need currently
if ~isempty(options.predefined_old_to_new_cell_array)
    old_to_new_cell_array = options.predefined_old_to_new_cell_array;
    num_cols_for_new_dataset = max(old_to_new_cell_array{end,3});
    data_to_fill = zeros(height(blind_pass_table),num_cols_for_new_dataset);
    sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
    for i=1:size(old_to_new_cell_array,1)
        current_old_idx = old_to_new_cell_array{i,1};
        current_new_idx = old_to_new_cell_array{i,3};
        
        parfor p=1:height(blind_pass_table)
            curr_data = sliced_bp_table{p};
            current_grades = curr_data.grades{1};
            current_grade = current_grades{current_old_idx};
            expected_num_grades = length(current_new_idx);
            if size(current_grade,1) > size(current_grade,2) %in the case of a col formatted grade, format it into a row
                current_grade = current_grade.';
            end
            if isempty(current_grade) & expected_num_grades > 0
                current_grade = zeros(1,expected_num_grades);
            elseif length(current_grade) < expected_num_grades
                current_grade = [current_grade,zeros(1,expected_num_grades - length(current_grade))];

            elseif length(current_grade) > expected_num_grades
                current_grade = current_grade(1:expected_num_grades);
            end

            data_to_fill(p,current_new_idx) = current_grade;
        end

    end
    padded_grades = data_to_fill;
    return;
end


%figure out which grades need to be padded
all_lengths = cellfun(@length, all_grades);
max_grade_length = max(all_lengths,[],1);

%now assemble all remaining grades, padding any ones that are per channel
%with zeros
grade_idxs_to_be_used = config.expanded_grade_idxs;

cell_array = cell(1,length(grade_idxs_to_be_used));
old_to_new_cell_array = cell(length(grade_idxs_to_be_used),3);
new_idx_tracker = 1;
for i=1:length(grade_idxs_to_be_used)
    non_padded_length = cellfun(@length,all_grades(:,grade_idxs_to_be_used(i)));

    %pad any data that doesn't have the max grade size
    arrays_to_pad = find(non_padded_length < max_grade_length(grade_idxs_to_be_used(i)));
    for j=1:length(arrays_to_pad)
        how_many_to_pad =abs( max_grade_length(grade_idxs_to_be_used(i))-non_padded_length(arrays_to_pad(j)));
        all_grades{arrays_to_pad(j),grade_idxs_to_be_used(i)} = [all_grades{arrays_to_pad(j),grade_idxs_to_be_used(i)}, zeros(1,how_many_to_pad)];
    end

    if grade_idxs_to_be_used(i) == 30 && 0==(max_grade_length(grade_idxs_to_be_used(i))) %hot fix because the grade is no longer computed, but we need it for compatibility
        all_grades(:,grade_idxs_to_be_used(i)) = repmat({0},size(all_grades,1),1);
        max_grade_length(grade_idxs_to_be_used(i)) = 1;
    end

    old_to_new_cell_array{i,1} = grade_idxs_to_be_used(i);
    old_to_new_cell_array{i,2} = i;
    old_to_new_cell_array{i,3} = new_idx_tracker:1:(new_idx_tracker+(max_grade_length(grade_idxs_to_be_used(i)))-1);

    new_idx_tracker = new_idx_tracker+max_grade_length(grade_idxs_to_be_used(i));



    cell_array{i} = cell2mat( cellfun(@double, all_grades(:,grade_idxs_to_be_used(i)), 'UniformOutput', false));


end
padded_grades = horzcat(cell_array{:});
end