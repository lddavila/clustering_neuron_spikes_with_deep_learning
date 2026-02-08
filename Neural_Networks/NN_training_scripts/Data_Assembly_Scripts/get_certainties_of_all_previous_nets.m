function updated_data = get_certainties_of_all_previous_nets(list_of_all_previous_nets, fp_with_nets, data)

n = size(data,1);
m = length(list_of_all_previous_nets);
previous_certainties = nan(n, m);

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
    Xs = rescale(X, 0, 1, "InputMax", netS.InputMax, "InputMin", netS.InputMin);

    % Predict
    scores = predict(net, Xs);   % Nx2 probs

    % Temperature calibration (on class 1 prob)
    p1_uncal = scores(:,2);
    p1_cal   = apply_temperature_binary(p1_uncal, T);

    % Certainty in [-1,1]
    previous_certainties(:, i) = 2*p1_cal - 1;
end

updated_data = [data, previous_certainties];
end
