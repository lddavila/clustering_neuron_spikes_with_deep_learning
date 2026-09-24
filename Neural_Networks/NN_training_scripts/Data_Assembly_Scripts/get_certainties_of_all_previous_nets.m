function [updated_data,unscaled_certainties]= get_certainties_of_all_previous_nets(list_of_all_previous_nets, fp_with_nets, data,options)
arguments
    list_of_all_previous_nets 
    fp_with_nets string
    data double
    options.use_z_score = false;
    options.mu = [];
    options.sigma = [];
end

n = size(data,1);
if class(list_of_all_previous_nets)=="table"
    names_of_files = string(list_of_all_previous_nets.name);
    split_names = split(names_of_files,"_");
    only_thresholds = str2double(split_names(:,3));
    list_of_all_previous_nets.thresholds = only_thresholds;
    sorted_rows = sortrows(list_of_all_previous_nets.name,"threshold","ascend");
    list_of_all_previous_nets = sorted_rows.name;
end
m = length(list_of_all_previous_nets);
previous_certainties = nan(n, m);
unscaled_certainties = nan(size(data,1),length(list_of_all_previous_nets));
for i = 1:m
    netS = importdata(fullfile(fp_with_nets, list_of_all_previous_nets(i)));
    net  = netS.net;
    T    = netS.temperature;

    % Build raw input this net was trained on
    if i == 1
        X = data;
    else
        X = [data, previous_certainties(:,1:i-1)];
    end

    % Scale full input using this net's stored scaling
    if ~options.use_z_score
        Xs = rescale(X, 0, 1, "InputMax", netS.InputMax, "InputMin", netS.InputMin);
    else
        Xs = (data - netS.mu) ./ netS.sigma;
    end

    % Predict
    scores = predict(net, Xs);   % Nx2 probs

    % Temperature calibration (on class 1 prob)
    p1_uncal = scores(:,2);
    p1_cal   = apply_temperature_binary(p1_uncal, T);

    % Certainty in [-1,1]
    previous_certainties(:, i) = 2*p1_cal - 1;
    unscaled_certainties(:,i) = 2*p1_cal -1;
end

updated_data = [data, previous_certainties];
end
