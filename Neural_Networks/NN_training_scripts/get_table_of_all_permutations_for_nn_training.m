function [permutations_table] = get_table_of_all_permutations_for_nn_training(table_var_names,varargin)
%the goal of this function is to create ahead of time all of the possible
%permutations of training data
%by doing this we can better train more neural nets at once
%a limitation that I curently have is the use of a nested for loop 
%ex 
%for meta_data_1_counter = 1:size(number_of_meta_data_1_to_try)
     %for meta_data_2_counter=1:size(possible_values_for_meta_data,2)
     %some work
     %end
 %end
 %it's unlikely that you have 40 of each metaparameters
 %so instead let's combine the meta parameters ahead of time
 %thus having only a single parfor loop
 %and establish dynamic builds

 %table_var_names should be a string array to name each column of the table
 %anything that comes in after table_var_names should be a series of double
 %arrays that show all possible meta parametrs
 %we'll combine these in such a way that we'll create a table where each
 %row is a possible combination of the meta parameters and each column
 %represents the meta parameter

all_perms_of_meta_data =combvec(varargin{:}).';
permutations_table = array2table(all_perms_of_meta_data,'VariableNames',table_var_names);
end