function [] = try_both_reclustering_methods_varying_order(blind_pass_table,config,channel_wise_means,channel_wise_std)

orders = {["split_by_amp","split_by_davies"],["split_by_davies","split_by_amp"],["split_by_davies"],["split_by_amp"]};
only_sample = false;
if only_sample
    tetrode_list = strcat("t",string(1:15:285));
    c1 = ismember(blind_pass_table{:,"Tetrode"},tetrode_list);
    blind_pass_table = blind_pass_table(c1,:);
end
table_vars = string(blind_pass_table.Properties.VariableNames);
if ismember("accuracy",table_vars) % a shortcut we do to save computation done, will never be available in real life
    blind_pass_table(blind_pass_table{:,"accuracy"}<10,:) = [];
end
results_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.BLIND_PASS_DIR_PRECOMPUTED,"reclustering_methods_results"));


for i=1:length(orders)
    curr_order = orders{i};
    which_already_run = zeros(length(curr_order),1);
    clusters_split_by_davies = [];
    clusters_split_by_amp = [];
    for j=1:length(curr_order)
        curr_to_run = curr_order(j);
        if curr_to_run == "split_by_davies"
            if which_already_run(2) == 1
                clusters_split_by_davies = split_clusters_with_alt_dimensions(clusters_split_by_amp,config,"ran_amp_split_first",true);
            else
                clusters_split_by_davies = split_clusters_with_alt_dimensions(blind_pass_table,config);
                which_already_run(1) = 1;
            end
        elseif curr_to_run == "split_by_amp"
            if which_already_run(1) == 1
                clusters_split_by_amp = recluster_by_amplitude_wrapper(clusters_split_by_davies,config,channel_wise_means,channel_wise_std,curr_order);
            else
                clusters_split_by_amp = recluster_by_amplitude_wrapper(blind_pass_table,config,channel_wise_means,channel_wise_std,curr_order);
                which_already_run(2) =1;
            end
        end
    end
    data_struct = struct();
    data_struct.clusters_split_by_davies = clusters_split_by_davies;
    data_struct.clusters_split_by_amp = clusters_split_by_amp;
    data_struct.blind_pass_table = blind_pass_table;
    save_name = fullfile(results_dir,strjoin(curr_order,"_")+".mat");
    par_save(save_name,data_struct);
end
end