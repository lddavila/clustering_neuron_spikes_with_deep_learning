function [sliced_table] = slice_table_for_parallel_processing(gen_table,slice_variables)
if ~isempty(slice_variables)
    group_count_table = groupcounts(gen_table,slice_variables);
    sliced_table = cell(size(group_count_table,1),1);
    for i=1:size(group_count_table,1)
        condition = zeros(size(gen_table,1),1) + 1; %by default take everything
        for j=1:size(slice_variables,2)
            condition = condition & gen_table{:,slice_variables(j)}==group_count_table{i,slice_variables(j)}; %get the rows of the table where all the conditions are met
        end
        sliced_table{i} = gen_table(condition,:); %store the desired rows in the sliced version of the table
    end
else
    sliced_table = cell(size(gen_table,1),1);
    for i=1:size(sliced_table,1)
        sliced_table{i} = gen_table(i,:);
    end

end

end