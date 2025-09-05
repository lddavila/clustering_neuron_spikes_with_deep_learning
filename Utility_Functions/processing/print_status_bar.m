function [] = print_status_bar(iterations,caller)
persistent count N function_name
if ~isempty(iterations)
    count = 0;
    N = iterations;
    function_name = caller;
else
    count = count+1;
    percent_done = 100 * (count / N);
    number_of_bars_to_print = round(percent_done);
    bar_string = repelem("|",1,number_of_bars_to_print);
    fprint("\r%s : %s",function_name,bar_string)
    if count==N
        fprintf("\n");
    end
end
end