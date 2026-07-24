function [] = plot_accuracy_of_blind_pass_table_vs_split_table_as_bar(blind_pass_table,split_blind_pass_table)
blind_pass_table.ref_id = (1:1:size(blind_pass_table,1)).';
for i=1:height(blind_pass_table)
    f = figure;
    curr_ref_id = blind_pass_table{i,"ref_id"};
    c1 = split_blind_pass_table{:,"ref_id"} == curr_ref_id;
    current_accuracies = [blind_pass_table{i,"accuracy"},split_blind_pass_table{c1,"accuracy"}.'];
    x_labels = ["og cluster",strcat("split cluster",string(1:sum(c1)))];
    bar(x_labels,current_accuracies);


    close(f);
end
end