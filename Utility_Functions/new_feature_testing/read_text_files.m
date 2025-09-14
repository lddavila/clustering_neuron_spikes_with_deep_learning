function [] = read_text_files()
fp_to_dir = "/scratch1/10595/lddavila/clustering_neuron_spikes_with_deep_learning/Default_Results_Dir/img_threshold_finding_incremental/accuracy_text_files/*.txt";
all_txt_files = struct2table(dir(fp_to_dir));
sliced_txt_files = slice_table_for_parallel_processing(all_txt_files,[]);
final_table = [];
num_iterations =length(sliced_txt_files);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
print_status_bar(num_iterations,"reading_accu_test_files.m")
parfor i=1:length(sliced_txt_files)
    current_data = sliced_txt_files{i};
    current_data_string = split(current_data{1,"name"},"_",2);
    tetrode = "t"+current_data_string(2);
    accuracy = str2double(current_data_string(4));
    z_score = str2double(current_data_string(6));
    channels = [str2double(current_data_string(8)),str2double(current_data_string(9)),str2double(current_data_string(10)),str2double(strrep(current_data_string(11),".txt",""))];
    current_row = table(z_score,tetrode,accuracy,channels,'VariableNames',["Z Score","Tetrode","accuracy","channels"]);
    final_table = [final_table;current_row];
    send(q,[]);
end
par_save(fullfile("/scratch1/10595/lddavila/clustering_neuron_spikes_with_deep_learning/Default_Results_Dir/img_threshold_finding_incremental","table_of_image_accuracy_data.mat"),final_table);
end