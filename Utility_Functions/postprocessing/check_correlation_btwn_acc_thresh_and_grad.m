function [table_of_correlation] = check_correlation_btwn_acc_thresh_and_grad(table_of_gradience_and_threshold,blind_pass_table)
list_of_variables = string(table_of_gradience_and_threshold.Properties.VariableNames);
table_of_correlation = [];
for i=1:size(list_of_variables,2)
    current_variable = list_of_variables(i);
    [R,P] = corrcoef(blind_pass_table{:,"accuracy"},table_of_gradience_and_threshold{:,current_variable});
    row = table(current_variable,R(1,2),P(1,2),'VariableNames',["Gradience_and_threshold","R","p-value"]);
    table_of_correlation = [table_of_correlation;row];
    print_status_iter_message("",i,size(list_of_variables,2));
end
table_of_correlation =sortrows(table_of_correlation,"R","descend");
end