function [] = get_first_n_seconds_of_recording(fp_with_recording,n,fp_to_save_new_recoridng)
new_ts_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(fp_to_save_new_recoridng,"timestamps"));
new_gt_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(fp_to_save_new_recoridng,"ground_truth"));
new_rec_by_chann_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(fp_to_save_new_recoridng,"recordings_by_channel"));
disp("Finished creating new directories")
%step 1 is to get the timestamps 
timestamps = importdata(fullfile(fp_with_recording,"timestamps","timestamps.mat"));
disp("Finished importing timestamps.")
%now find the index where the time stamps hit n
index_of_n_seconds =  find(timestamps >= n,1);

new_ts = timestamps(1:index_of_n_seconds);
save(fullfile(new_ts_dir,"timestamps.mat"),"new_ts");
disp("Finished saving timestamps")
%now that we know where in the recording our length ends we can modify all
%the channel and ground truth files

list_of_channel_files = struct2table(dir(fullfile(fp_with_recording,"recordings_by_channel","*.mat")));
list_of_channel_files = string(list_of_channel_files{:,"name"});
q = parallel.pool.DataQueue;
afterEach(q,@print_message_using_dataqueue)
num_iterations = size(list_of_channel_files,1);
print_message_using_dataqueue(num_iterations,"slicing_channels")
parfor i=1:size(list_of_channel_files,1)
    current_channel_data = importdata(fullfile(fp_with_recording,"recordings_by_channel",list_of_channel_files(i)));
    current_channel_data = current_channel_data(1:index_of_n_seconds);
    par_save(fullfile(new_rec_by_chann_dir,list_of_channel_files(i)),current_channel_data);
    send(q,[]);
end
q = parallel.pool.DataQueue;
afterEach(q,@print_message_using_dataqueue)
num_iterations = size(list_of_channel_files,1);
print_message_using_dataqueue(num_iterations,"slicing_gt")
ground_truth_array = importdata(fullfile(fp_with_recording,"ground_truth","ground_truth.mat"));
parfor i=1:length(ground_truth_array)
    current_ground_truth = ground_truth_array{i};
    current_ground_truth(current_ground_truth>index_of_n_seconds) = [];
    ground_truth_array{i} = current_ground_truth;
    send(q,[]);
end


save(fullfile(new_gt_dir,"ground_truth.mat"),"ground_truth_array");
disp("Finished")

end