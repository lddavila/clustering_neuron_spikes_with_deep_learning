function [contains_all_cols] = check_for_required_cols(table_to_check,cols_that_should_be_present,file_that_called,reccomended_step,supress_message)
variables_in_table = table_to_check.Properties.VariableNames;
contains_all_cols = true;
%add_is_neuron_col
for i=1:size(cols_that_should_be_present,2)
    if ~ismember(cols_that_should_be_present(i),variables_in_table)
        contains_all_cols = false;
        if ~supress_message
            disp("File That Called")
            disp(file_that_called)
            disp("Recommended")
            disp(reccomended_step)
            disp("Missing Col Name:")
            disp(cols_that_should_be_present(i))
        end
        break;
    end
end
end