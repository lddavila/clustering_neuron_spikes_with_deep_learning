function [table_of_gradience_and_threshold] = add_various_cols_of_over_percentage_above_n(blind_pass_table,gradience_levels_to_add,overlap_thresholds_to_try)
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
table_of_gradience_and_threshold = cell2table({});
for i=1:size(gradience_levels_to_add,2)
    actual_under_unit_class = zeros(size(blind_pass_table,1),1);
    q = parallel.pool.DataQueue;
    afterEach(q,@print_message_using_dataqueue)
    num_iterations = size(actual_under_unit_class,1);
    print_message_using_dataqueue(num_iterations,"add_various_cols_of_over_percentage_above_n.m")
    levels_of_granularity = gradience_levels_to_add(i);
    for ov_th_counter =1: size(overlap_thresholds_to_try,2)
        minimum_overlap_threshold = overlap_thresholds_to_try(ov_th_counter);
        for j=1:size(actual_under_unit_class,1)
            current_data = sliced_bp_table{j};
            overlaps_with_all_units = current_data{1,"overlap % with all units"}{1};
            over_min_count = sum(overlaps_with_all_units>minimum_overlap_threshold,"all");
            %determine which bin this exists in
            %by default it will be 0 unless proved otherwhile
            if over_min_count >levels_of_granularity
                actual_under_unit_class(j) = levels_of_granularity;
            else
                actual_under_unit_class(j) =over_min_count ;
            end
            %send(q,[])
        end
        table_of_gradience_and_threshold.(gradience_levels_to_add(i)+"_gradience_levels_overlap_threshold"+string(overlap_thresholds_to_try(ov_th_counter))) = actual_under_unit_class;
    end
    
    print_status_iter_message("add_various_cos_of_over_percentage_above_n.m",i,size(gradience_levels_to_add,2) * size(overlap_thresholds_to_try,2));
end

end