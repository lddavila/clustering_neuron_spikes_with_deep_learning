function [blind_pass_table] = add_above_below_probabilities_col(blind_pass_table,config)
%well use this function to get probabilities on whether or not any given
%cluster is above/below a certain accuracy threshold
%these probabilities will be helpful when building the choose better neural
%network and trying to get accuracy categories
table_of_boundary_nns = config.table_of_boundary_nn;

%extract the grades from each row of the blind pass table to use for the
%above/below nets
list_of_features_to_add = ["grades 2"];   
grades = assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config);
grades = grades{1};

%for for each neural network we'll get the boundary probabilities
for i=1:size(table_of_boundary_nns,1)
    current_net = importdata(fullfile(table_of_boundary_nns{i,"folder"}{1},table_of_boundary_nns{i,"name"}{1}));
    %rescale the grades based on the net data
    rescaled_grades = rescale(grades,-1,1,"InputMax",current_net.InputMax,"InputMin",current_net.InputMin);
    scores = predict(current_net.net,rescaled_grades);
    split_current_name = split(table_of_boundary_nns{i,"name"},"_");
    threshold = strrep(split_current_name{3},"accuracy","");
    blind_pass_table.("above_below_"+threshold) = scores;
end
end