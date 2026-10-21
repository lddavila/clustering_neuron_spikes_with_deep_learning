q = parallel.pool.DataQueue;

afterEach(q,@print_status_bar)

num_iterations = length(sliced_4_ch);

print_status_bar(num_iterations,"reassemble_from_sliced_data.m")
bp_4_ch = [];
parfor i=1:length(sliced_4_ch)
    current_data = sliced_4_ch{i};
    bp_4_ch = [bp_4_ch;current_data(:,all_vars)];
	send(q,[])
end