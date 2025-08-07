function [] = print_message_using_dataqueue(iterations)
persistent count N
if nargin==2
    count = 0;
    N = iterations;
else
    count = count+1;
    print_status_iter_message("",count,N);
end
end