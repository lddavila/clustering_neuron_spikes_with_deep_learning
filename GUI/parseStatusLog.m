function status = parseStatusLog(logFile)
  status = struct( ...
    'iterDone',   containers.Map('KeyType','char','ValueType','any'), ...
    'totalCount', containers.Map('KeyType','char','ValueType','double') ...
  );

  if ~isfile(logFile)
    return;
  end

  expr = '^(?<func>\w+)\s+Finished\s+(?<iter>\d+)\/(?<total>\d+)';
  lines = readlines(logFile);

  for L = lines(:).'
    tk = regexp(L, expr, 'names', 'once');
    if isempty(tk), continue; end

    fn   = tk.func;
    it   = str2double(tk.iter);
    tot  = str2double(tk.total);

    % Which iteration
    if isKey(status.iterDone, fn)
      status.iterDone(fn) = unique([status.iterDone(fn), it]);
    else
      status.iterDone(fn) = it;
    end

    % The total
    if ~isKey(status.totalCount, fn)
      status.totalCount(fn) = tot;
    end
  end
end
