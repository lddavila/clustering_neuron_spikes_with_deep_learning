function [] = data_queue_tests()
%create a dataqueue object
q = parallel.pool.DataQueue;
afterEach(q,@print_message_using_dataqueue)
num_iterations = 100;
print_message_using_dataqueue(num_iterations,"data_queue_tests.m")
parfor i=1:100
    pause(rand)
    send(q,[])
end

end