function timestamp_filter = compute_timestamp_filter(timestamps)
%COMPUTE_TIMESTAMP_FILTER Creates a filter to ignore moments in time where
%there is abnormally high activity.
%   timestamp_filter = COMPUTE_TIMESTAMP_FILTER(timestamps)
%
%   'timestamps' are the timestamps for each spike in microseconds.
%
%   'timestamp_filter' is a logical index array for all spikes which are
%   not in intervals with abnormally high activity.

    timestamp_filter = true(length(timestamps), 1);
    x = timestamps(1):0.08e6:timestamps(end);
    n = histc(timestamps, x);
    edge_filter = n > mean(n) + 5*std(n);
    edges = x(edge_filter);
    for edge = edges
        timestamp_filter(edge - 0.08e6 <= timestamps & timestamps <= edge + 0.08e6) = false;
    end
end