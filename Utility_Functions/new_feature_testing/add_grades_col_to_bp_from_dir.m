function [blind_pass_table] = add_grades_col_to_bp_from_dir(blind_pass_table,grades_dir)

tetrodes_table = struct2table(dir(fullfile(grades_dir,"*.mat")));
tetrode_list = string(tetrodes_table.name);
tetrode_list = strrep(tetrode_list," Grades.mat","");

c1 = ismember(blind_pass_table{:,"Tetrode"},tetrode_list);
blind_pass_table(~c1,:) = [];
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,"fp_to_aligned");
for i=1:length(sliced_bp_table)
    current_data = sliced_bp_table{i};
    current_tetrode = current_data{1,"Tetrode"};
    grades_file_name = fullfile(grades_dir,current_tetrode+" Grades.mat" );
    grades_struct = load(grades_file_name);
    grades_struct = grades_struct.data_to_save;
    grades_struct = struct2table(grades_struct);
    grades = cell(size(grades_struct,1),size(grades_struct,2));
    for row_counter = 1:size(grades_struct,1)
        for col_counter = 1:size(grades_struct,2)
            grades{row_counter,col_counter} = grades_struct{row_counter,col_counter}{1};
        end
    end
    current_data.grades = grades;
    sliced_bp_table{i} = current_data;
end
blind_pass_table = vertcat(sliced_bp_table{:});
end