function [blind_pass_table] = add_cluster_idx_and_ts_for_clusters(blind_pass_table,config,varargin)
% blind_pass_table = update_fpths(blind_pass_table,spikesort_config);
local_error_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.error_dir,"add_cluster_idx_and_ts_for_clusters"));
sliced_blind_pass_table = slice_table_for_parallel_processing(blind_pass_table,["fp_to_aligned"]);

q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = size(sliced_blind_pass_table,1);
print_status_bar(num_iterations,"get_template_spike_idx_and_ts_for_clusters.m")
if isempty(varargin)
    timestamps_array = importdata(config.TIMESTAMP_FP);
else
    timestamps_array = varargin{4};
end
for i=1:size(sliced_blind_pass_table,1)
    try

        current_data = sliced_blind_pass_table{i};

        current_data_vars = string(current_data.Properties.VariableNames);
  
        if isempty(varargin)
            if ~ismember("cluster_idx",current_data_vars)
                try

                    cleaned_clusters =load(current_data{1,"fp_to_cleaned_clusters"},"cleaned_clusters");
                    cleaned_clusters = cleaned_clusters.cleaned_clusters;
                catch
                    disp("Failed to load cleaned clusters file")
                    disp(current_data{1,"fp_to_cleaned_clusters"})
                    send(q,[]);
                    continue;
                end
            else
                cleaned_clusters = current_data.cluster_idx;
            end

            try
                aligned_struct = load(current_data{1,"fp_to_aligned"},"data_to_save");
                aligned = aligned_struct.data_to_save;
                num_of_channels = size(aligned,1);
            catch ME
                disp(ME.getReport);
                send(q,[]);
                continue;
            end
            base_spike_windows_fp =current_data{1,"fp_to_sorted_spike_windows_after_purges"};
            base_spike_windows_struct = load(base_spike_windows_fp,"data_to_save");
            base_spike_windows = base_spike_windows_struct.data_to_save;
            timestamps = timestamps_array(base_spike_windows(:,4));


        else
            cleaned_clusters = varargin{1};
            aligned = varargin{2};
            timestamps = varargin{3};
        end


        idx_cell_array = cell(size(current_data,1),1);
        timestamp_cell_array = cell(size(current_data,1),1);
        for j=1:length(cleaned_clusters)
            cluster_filter = cleaned_clusters{j};
            idx_cell_array{j} = cluster_filter;
            timestamp_cell_array{j} = timestamps(cluster_filter);
        end
        current_data.("cluster_idx") = idx_cell_array;
        current_data.("timestamps") = timestamp_cell_array;
        sliced_blind_pass_table{i} = current_data;

    catch ME
        report = ME.getReport;
        if config.use_new_spike_detection
            meta_data_text = sprintf("error when i = %i\n tetrode: %s \n Multiplier or Z score: %i\n",i,current_data{1,"Tetrode"},current_data{1,"Multiplier"});
            f_id = fopen(fullfile(local_error_dir,sprintf("tetrode %s Multiplier or Z score %i",current_data{1,"Tetrode"},current_data{1,"Multiplier"})+".txt"),"w");
        else
            meta_data_text = sprintf("error when i = %i\n tetrode: %s \n Multiplier or Z score: %i\n",i,current_data{1,"Tetrode"},current_data{1,"Z Score"});
            f_id = fopen(fullfile(local_error_dir,sprintf("tetrode %s Multiplier or Z score %i",current_data{1,"Tetrode"},current_data{1,"Z Score"})+".txt"),"w");
        end

        if f_id == -1
            error('File could not be opened.');
        end
        fprintf(f_id,meta_data_text);
        fprintf(f_id,report);
        fclose(f_id);
    end
    send(q,[]);
end
par_save(fullfile(local_error_dir,"sliced_bp_table.mat"),sliced_blind_pass_table);
sliced_blind_pass_table = sliced_blind_pass_table(~cellfun(@isempty, sliced_blind_pass_table));
blind_pass_table = vertcat(sliced_blind_pass_table{:});
end