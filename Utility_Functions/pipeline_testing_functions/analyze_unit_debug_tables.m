function [] = analyze_unit_debug_tables(cell_array_of_unit_detection_tables)
for i=1:length(cell_array_of_unit_detection_tables)
    current_table = cell_array_of_unit_detection_tables{i};
    if any(current_table{:,"detection_ratio_after_dict_creation"} > 70)
        % disp(current_table(current_table{:,"detection_ratio_after_dict_creation"} > 70,:))
    end
    disp(current_table)
    fprintf("%i/%i\n",i,length(cell_array_of_unit_detection_tables))
end
end