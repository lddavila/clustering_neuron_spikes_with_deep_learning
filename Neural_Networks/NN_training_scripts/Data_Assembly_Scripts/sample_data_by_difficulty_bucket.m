function [comparisons,true_class,difficulty_buckets] = sample_data_by_difficulty_bucket(comparisons,true_class,difficulty_buckets)
unique_difficulty_buckets = unique(difficulty_buckets);
bucket_tabulation = tabulate(difficulty_buckets);
min_bucket = min(bucket_tabulation,[],1);
min_bucket = min_bucket(2);
cell_array_of_idxs = cell(length(unique_difficulty_buckets),1);
for i=1:length(unique_difficulty_buckets)
    %define all comparisons in the current difficulty bucket
    disp(i)

    [row,~] = find(difficulty_buckets==unique_difficulty_buckets(i));

    % disp(length(row))
    % disp(min_bucket)
    % disp("##############################")
    if isempty(row)
        continue;
    end
    %randomly sample the indexes
    randomly_sampled_idxs = randperm(length(row),min_bucket);

    cell_array_of_idxs{i} = row(randomly_sampled_idxs);
end

%now index all the data to match the randomly selected indexes
comparisons = comparisons(reshape(cell2mat(cell_array_of_idxs),[],1),:);
true_class = true_class(reshape(cell2mat(cell_array_of_idxs),[],1),:);
difficulty_buckets = difficulty_buckets(reshape(cell2mat(cell_array_of_idxs),[],1),:);
end