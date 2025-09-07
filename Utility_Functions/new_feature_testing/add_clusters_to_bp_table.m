function [blind_pass_table] = add_clusters_to_bp_table(blind_pass_table)
%this function is used by modified_run_entire_clustering_algorithm.m in
%order to only get the timestamps cluster numbers while avoding grading
%which is typically required
%we do this to save computation time for the ratio testing
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,["fp_to_output"]);
new_data = cell(size(sliced_bp_table{1}));
parfor i=1:size(sliced_bp_table,1)
    current_data = sliced_bp_table{i};
    try
        output = importdata(current_data{1,"fp_to_output"});
        output = output.output;
    catch
        disp("Failed to load output file")
        disp(current_data{1,"fp_to_output"})
        continue;
    end

    try
        timestamps = importdata(current_data{1,"fp_to_reg_timestamps_of_the_spikes"});
        timestamps = timestamps.reg_timestamps_of_the_spikes;
    catch
        disp("Failed to load timestamps of spikes");
        disp(current_data{1,"fp_to_reg_timestamps_of_spikes"});
        continue;
    end
    idx_b4_filt = extract_clusters_from_output(output(:,1),output);


    idx_cell_array = cell(length(idx_b4_filt),1);
    timestamp_cell_array = cell(length(idx_b4_filt),1);
    for j=1:length(idx_b4_filt)
        cluster_filter = idx_b4_filt{j};
        idx_cell_array{j} = cluster_filter;
        timestamp_cell_array{j} = timestamps(cluster_filter);
    end
    current_new_data = table(repelem(current_data{1,"fp_to_output"},length(idx_cell_array),1),(1:length(idx_cell_array)).',idx_cell_array,timestamp_cell_array,'VariableNames',["fp_to_output","Cluster","cluster_idx","timestamps"]);


    new_data{i} = join(current_new_data,current_data);
end
blind_pass_table = vertcat(new_data{:});
end