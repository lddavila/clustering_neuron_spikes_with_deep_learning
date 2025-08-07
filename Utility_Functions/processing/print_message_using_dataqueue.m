function [] = print_message_using_dataqueue(iterations,caller)
persistent count N function_name
if ~isempty(iterations)
    count = 0;
    N = iterations;
    function_name = caller;
else
    count = count+1;
    % fprintf("Made it here %i times",count)
    fprintf("%s Finished %i / %i\n",function_name,count,N)
end
end