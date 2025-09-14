function [] = print_status_bar(iterations, caller)
persistent count N function_name barW prevLen
if ~isempty(iterations)
    count = 0;
    N = iterations;
    function_name = caller;
    barW = 50;           % width of the bar (chars)
    prevLen = 0;         % how many chars we printed last time
else
    count = min(count + 1, N);
    frac  = count / N;
    filled = max(0, min(barW, round(frac * barW)));

    bar_string = [repmat('|',1,filled), repmat('-',1,barW-filled)];
    msg = sprintf('%s : [%s] %6.2f%%  %d/%d', function_name, bar_string, 100*frac, count, N);

    % erase previous message (works even if it wrapped)
    if prevLen > 0
        fprintf(1, repmat('\b', 1, prevLen));
    end

    % print new message (no newline)
    fprintf(1, '%s', msg);
    prevLen = length(msg);

    if count == N
        fprintf(1, '\n');   % finish with a newline
        prevLen = 0;
    end
end
drawnow limitrate nocallbacks
end
