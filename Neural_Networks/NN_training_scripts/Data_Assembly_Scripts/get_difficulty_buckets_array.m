function [difficulty_level] = get_difficulty_buckets_array(mag_of_accuracy_differences,buckets_of_difficulty)
difficulty_level = nan(length(mag_of_accuracy_differences),1);
for i=1:length(mag_of_accuracy_differences)
    for j=1:length(buckets_of_difficulty)-1
        if mag_of_accuracy_differences(i) >= buckets_of_difficulty(j) && mag_of_accuracy_differences(i) < buckets_of_difficulty(j+1)
            difficulty_level(i) = j;
            break;
        elseif j ==length(buckets_of_difficulty)-1 && mag_of_accuracy_differences(i) > buckets_of_difficulty(j+1)
            difficulty_level(i) = j+1;
        end
    end
end
end