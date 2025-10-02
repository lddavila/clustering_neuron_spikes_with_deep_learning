function [blind_pass_table] = add_is_neuron_col(blind_pass_table,config)
array_of_is_neuron = nan(size(blind_pass_table,1),1);
sliced_blind_pass_table = slice_table_for_parallel_processing(blind_pass_table,[]);
config =parallel.pool.Constant(config);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = size(blind_pass_table,1);
print_status_bar(num_iterations,"add_is_neuron_col.m")
for i=1:size(blind_pass_table,1)
    current_data = sliced_blind_pass_table{i};
    current_grades = current_data{1,"grades"}{1};
    [~,idx_of_MUA] = find(config.Value.NAMES_OF_CURR_GRADES=="MUA or Not");
    array_of_is_neuron(i) = current_grades{idx_of_MUA};
    send(q,[]);
end
blind_pass_table.("is_neuron") =array_of_is_neuron;
end