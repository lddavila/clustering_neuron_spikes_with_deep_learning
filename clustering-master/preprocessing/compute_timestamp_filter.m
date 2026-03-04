%edited by Luis David Davila and Alexander Friedman
function the_timestamp_filter = compute_timestamp_filter(the_timestamps)
%COMPUTE_TIMESTAMP_FILTER Creates a filter to ignore moments in time where
%there is abnormally high activity.
%   timestamp_filter = COMPUTE_TIMESTAMP_FILTER(timestamps)
%
%   'timestamps' are the timestamps for each spike in microseconds.
%
%   'timestamp_filter' is a logical index array for all spikes which are
%   not in intervals with abnormally high activity.

    the_timestamp_filter = true(length(the_timestamps), 1);
    x = the_timestamps(1):0.08e6:the_timestamps(end);
    n = histc(the_timestamps, x);
    edge_filter = n > mean(n) + 5*std(n);
    edges = x(edge_filter);
    for edge = edges
        the_timestamp_filter(edge - 0.08e6 <= the_timestamps & the_timestamps <= edge + 0.08e6) = false;
    end
end