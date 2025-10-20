function stop = custom_early_stop(info)
stop = false;
persistent consecutive
if isempty(consecutive)
    consecutive = 0;
end
if isfield(info,'State') && info.State == "start"
    consecutive = 0;
    return;
end
if isfield(info,'ValidationAccuracy') && ~isempty(info.ValidationAccuracy) && ~isnan(info.ValidationAccuracy)
    acc = info.ValidationAccuracy;
    % Handle either scale: 0–1 or 0–100
    if acc > 1
        acc = acc / 100;
    end

    if acc >= 1.0
        consecutive = consecutive + 1;
    else
        consecutive = 0;
    end

    if consecutive >= 3
        stop = true;
    end
end

% optional: cleanup at done
if isfield(info,'State') && info.State == "done"
    consecutive = [];
end


end