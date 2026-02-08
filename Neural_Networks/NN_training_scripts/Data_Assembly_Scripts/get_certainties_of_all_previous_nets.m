function [updated_data] = get_certainties_of_all_previous_nets(list_of_all_previous_nets,fp_with_nets,data)
if length(list_of_all_previous_nets)==1
    last_net = importdata(fullfile(fp_with_nets,list_of_all_previous_nets(1)));
    last_col_max = last_net.InputMax;
    last_col_min = last_net.InputMin;
    layers_of_last_net = last_net.net;
    training_data_scaled_as_last = rescale(data,-1,1,"InputMax",last_col_max,'InputMin',last_col_min);
    results_of_last_net = predict(layers_of_last_net,training_data_scaled_as_last);
    certainty = results_of_last_net(:,2) - results_of_last_net(:,1);
    updated_data = [data,certainty];
else
    updated_data = get_certainties_of_all_previous_nets(list_of_all_previous_nets(2:end),fp_with_nets,data);
    
end
end