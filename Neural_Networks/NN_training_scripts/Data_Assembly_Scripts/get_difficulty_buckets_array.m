function [difficulty_level] = get_difficulty_buckets_array(mag_of_accuracy_differences,buckets_of_difficulty,varargin)
%varargin should be 1 when you want to label any data that doesn't fall
%into any of the predetermined buckets with a NaN to be excluded
%without the default behavior it will be just be lumped into the highest
%bucket by default
difficulty_level = nan(length(mag_of_accuracy_differences),1);
for i=1:length(mag_of_accuracy_differences)
    for j=1:length(buckets_of_difficulty)-1
        if mag_of_accuracy_differences(i) >= buckets_of_difficulty(j) && mag_of_accuracy_differences(i) < buckets_of_difficulty(j+1)
            difficulty_level(i) = j;
            break;
        elseif j ==length(buckets_of_difficulty)-1 && mag_of_accuracy_differences(i) > buckets_of_difficulty(j+1) && isempty(varargin)            
            difficulty_level(i) = j+1;
        elseif j ==length(buckets_of_difficulty)-1 && mag_of_accuracy_differences(i) > buckets_of_difficulty(j+1) && varargin{1}         
            difficulty_level(i) = NaN;
        end
    end
end
end