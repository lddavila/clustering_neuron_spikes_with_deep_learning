function [] = test_how_grade_idxs_are_different(blind_pass_table,config)
%method 1 of getting grades
[grade_names,all_grades]= flatten_grades_cell_array(blind_pass_table{:,"grades"},config);
[indexes_of_grades_were_looking_for,~] = find(ismember(grade_names,config.NAMES_OF_CURR_GRADES(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST)));
grades_array = all_grades(:,indexes_of_grades_were_looking_for);
%method 2 of getting grades

compare_neuron_grades = cell2mat(blind_pass_table{1,"grades"}{1}(config.GRADE_IDXS_THAT_ARE_USED_TO_PICK_BEST));


end