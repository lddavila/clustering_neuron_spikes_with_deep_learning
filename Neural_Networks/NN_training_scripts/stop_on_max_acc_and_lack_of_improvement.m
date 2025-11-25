function stop = stop_on_max_acc_and_lack_of_improvement(info)
persistent consecutive bestValAcc lastImprovedEpoch

% Default output
stop = false;

% Initialize persistent vars on first call
if isempty(consecutive)
    consecutive      = 0;
    bestValAcc       = -inf;
    lastImprovedEpoch = 0;
end

% Handle start of training
if isfield(info,'State') && info.State == "start"
    consecutive       = 0;
    bestValAcc        = -inf;
    lastImprovedEpoch = 0;
    return;
end

% Main logic (iteration phase)
if isfield(info,'ValidationAccuracy') && ...
        ~isempty(info.ValidationAccuracy) && ...
        ~isnan(info.ValidationAccuracy)

    acc = info.ValidationAccuracy;

    % Handle either scale: 0–1 or 0–100
    if acc > 1
        acc = acc / 100;
    end

    % Track consecutive epochs above threshold
    if acc >= 0.991
        consecutive = consecutive + 1;
    else
        consecutive = 0;
    end

    % Early stop if high accuracy for 3 consecutive epochs
    if consecutive >= 3
        stop = true;
    end

    % Update best accuracy and last improv epoch
    if acc > bestValAcc
        bestValAcc        = acc;              % fixed
        lastImprovedEpoch = info.Epoch;
    end
end

% Also stop if no improvement for 5 epochs
if (info.Epoch - lastImprovedEpoch) >= 5
    stop = true;   % OR combine: stop = stop || ...
end

% Cleanup at done (optional)
if isfield(info,'State') && info.State == "done"
    consecutive       = [];
    bestValAcc        = [];
    lastImprovedEpoch = [];
end
end
