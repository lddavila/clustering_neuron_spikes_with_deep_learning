function [blind_pass_table] = add_number_of_overlap_percentages_above_one_col(blind_pass_table,levels_of_granularity)

%modified so that you actually bin the number of overlap units because the actual values are too gradient
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
actual_under_unit_class = zeros(size(blind_pass_table,1),1);
for i=1:size(blind_pass_table,1)
    current_data = sliced_bp_table{i};
    overlaps_with_all_units = current_data{1,"overlap % with all units"}{1};
    over_min_count = sum(overlaps_with_all_units>10,"all");
    %determine which bin this exists in 
    %by default it will be 0 unless proved otherwhile
    if over_min_count >levels_of_granularity
        actual_under_unit_class(i) = levels_of_granularity;
    else
        actual_under_unit_class(i) =over_min_count ;
    end

end
blind_pass_table.("num_of_overlap_percentages_over_1") = actual_under_unit_class;
disp("Finished getting under unit data.")
end