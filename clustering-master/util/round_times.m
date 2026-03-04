%edited by Luis David Davila and Alexander Friedman
function the_times = round_times(the_ts)
%ROUND_TIMES Rounds the times to the nearest millisecond
%
%Assumption: The times are currently in microseconds.
    the_times = round(the_ts * 1e3);
end