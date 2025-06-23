function times = round_times(ts)
%ROUND_TIMES Rounds the times to the nearest millisecond
%
%Assumption: The times are currently in microseconds.
    times = round(ts * 1e3);
end