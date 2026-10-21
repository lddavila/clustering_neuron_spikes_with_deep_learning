function [] = print_status_bar(iterations, caller)
persistent count N function_name barW prevLen lastPercent

if ~isempty(iterations)
    count = 0;
    N = iterations;
    function_name = caller;
    barW = 50;
    prevLen = 0;
    lastPercent = -1;
    return
end

% Ignore callbacks after completion.
if count >= N
    return
end

count = min(count + 1, N);
frac = count / N;
currentPercent = floor(100 * frac);

% Only redraw when a new whole-number percentage is reached.
if currentPercent <= lastPercent && count < N
    return
end
lastPercent = currentPercent;

filled = max(0, min(barW, round(frac * barW)));
bar_string = [repmat('|', 1, filled), repmat('-', 1, barW-filled)];

msg = sprintf('%s : [%s] %6.2f%%  %d/%d', ...
    function_name, bar_string, 100*frac, count, N);

if prevLen > 0
    fprintf(1, repmat('\b', 1, prevLen));
end

fprintf(1, '%s', msg);
prevLen = length(msg);

if count == N
    fprintf(1, '\n');
    prevLen = 0;
end

drawnow limitrate nocallbacks
end