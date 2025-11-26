function [equalized_nn_data] = equalize_classes(nn_data)
if class(nn_data)~="table"
    nn_data = array2table(nn_data);
end
counts_by_class = groupcounts(nn_data,string(nn_data.Properties.VariableNames(end)));
[min_counts,min_index] = min(counts_by_class{:,"GroupCount"});
equalized_nn_data = cell(size(counts_by_class,1),1);
for i=1:size(counts_by_class,1)
    is_in_current_class = nn_data{:,end} == counts_by_class{i,1};
    if i==min_index
        equalized_nn_data{i} = nn_data(is_in_current_class,:);
    else
        current_class_samples = nn_data(is_in_current_class,:);
        random_idxs = randperm(size(current_class_samples,1),min_counts);
        equalized_nn_data{i} = current_class_samples(random_idxs,:);

    end
end
equalized_nn_data = vertcat(equalized_nn_data{:});
shuffled_idxs = randperm(size(equalized_nn_data,1));
equalized_nn_data = equalized_nn_data(shuffled_idxs,:);
equalized_nn_data = equalized_nn_data{:,:};

end