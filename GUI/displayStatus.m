function displayStatus(Config, message)
    msg = string(message);
    cur = Config.STATUS_WINDOW.Value;
    if isempty(cur)
        newVal = msg;
    else
        % Append a new row
        newVal = [cur; msg];
    end
    % Config.STATUS_WINDOW.Value = newVal;
    set(Config.STATUS_WINDOW,'Value',newVal);
end