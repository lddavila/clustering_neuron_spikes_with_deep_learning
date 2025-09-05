function [] = print_status_bar(iterations,caller)
persistent count N function_name barW
if ~isempty(iterations)
    count = 0;
    N = iterations;
    function_name = caller;
    barW = 50;  % width of the bar (chars)
    fprintf('%s : [%s] %6.2f%%\n', function_name, repmat('-',1,barW), 0);
else
    count = min(count + 1, N);
    frac = count / N;
    filled = max(0, min(barW, round(frac * barW)));

    bar_string = [repmat('|',1,filled), repmat('-',1,barW-filled)];
    fprintf('\r%s : [%s] %6.2f%%  %d/%d\n', function_name, bar_string, 100*frac, count, N);
    if count==N
        fprintf("\n");
    end
end
drawnow limitrate nocallbacks  % keeps Command Window snappy
end