function [actual_under_unit_class] = get_under_unit_info_with_n_levels_of_grad_and_min_threshold_m(blind_pass_table,string_that_contains_gradience_and_threshold_level)
%string_that_contains_gradience_and_threshold_level= "under_unit_gradienceLevelN_minThresholdM";
split_data = split(string_that_contains_gradience_and_threshold_level,"_");
gradience_level = str2double(split_data(3));
threshold_level = str2double(split_data(4));
%modified so that you actually bin the number of overlap units because the actual values are too gradient
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
actual_under_unit_class = zeros(size(blind_pass_table,1),1);
parfor i=1:size(blind_pass_table,1)
    current_data = sliced_bp_table{i};
    overlaps_with_all_units = current_data{1,"overlap % with all units"}{1};
    over_min_count = sum(overlaps_with_all_units>threshold_level,"all");
    %determine which bin this exists in 
    %by default it will be 0 unless proved otherwhile
    if over_min_count >gradience_level
        actual_under_unit_class(i) = gradience_level;
    else
        actual_under_unit_class(i) =over_min_count ;
    end

end
disp("finished getting under unit for")
disp(string_that_contains_gradience_and_threshold_level)

end