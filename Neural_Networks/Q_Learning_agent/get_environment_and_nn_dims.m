function [min_number_of_samples,number_of_features,grades_cell_array,accuracy_cat_dividers] = get_environment_and_nn_dims(number_of_acc_cats,presorted_table,grades_size,grades_array)
accuracy_cat_dividers = linspace(1,100,number_of_acc_cats+1);
number_of_available_samples_per_bin = nan(1,number_of_acc_cats);
idxs_of_grades_in_current_boundry = cell(1,number_of_acc_cats);
for i=1:size(accuracy_cat_dividers,2)-1
    lower_bound_cond = presorted_table{:,"accuracy"} >accuracy_cat_dividers(i);
    upper_bound_cond = presorted_table{:,"accuracy"} <= accuracy_cat_dividers(i+1);
    idxs_of_grades_in_current_boundry{i} = lower_bound_cond & upper_bound_cond;
    number_of_available_samples_per_bin(i) = sum(lower_bound_cond & upper_bound_cond);
end
min_number_of_samples = min(number_of_available_samples_per_bin);

number_of_features = (min_number_of_samples+1)*grades_size;

grades_cell_array = cell(number_of_acc_cats,1);

for i=1:size(grades_cell_array,1)
    within_current_boundry = presorted_table(idxs_of_grades_in_current_boundry{i},:);
    idxs_to_use = randperm(min_number_of_samples);
    random_samples = within_current_boundry{idxs_to_use,"OG_IDX"};
    grades_cell_array{i} = reshape(grades_array(random_samples,:),1,[]);
end
end