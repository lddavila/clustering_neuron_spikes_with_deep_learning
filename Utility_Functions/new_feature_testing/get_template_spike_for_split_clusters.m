function [blind_pass_table] = get_template_spike_for_split_clusters(blind_pass_table,config,varargin)
% blind_pass_table = update_fpths(blind_pass_table,spikesort_config);
local_error_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.error_dir,"get_template_spike_idx_and_ts_for_clusters_errors"));
sliced_blind_pass_table = slice_table_for_parallel_processing(blind_pass_table,["Z Score","Tetrode"]);

q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = size(sliced_blind_pass_table,1);
print_status_bar(num_iterations,"get_template_spike_for_split_clusters.m")

for i=1:size(sliced_blind_pass_table,1)
    try

        current_data = sliced_blind_pass_table{i};
        num_of_channels =2;


        cleaned_clusters = current_data.cluster_idx;
        try
            aligned_struct = load(current_data{1,"fp_to_aligned"},"data_to_save");
            aligned = aligned_struct.data_to_save;
        catch ME
            disp(ME.getReport);
            send(q,[]);
            continue;
        end



        all_peaks = get_peaks(aligned, true);
        mean_waveform_cell_array = cell(size(current_data,1),num_of_channels);
        for j=1:height(current_data)
            num_of_channels = length(current_data{j,"channels"}{1});
            cluster_filter = cleaned_clusters{j};
            spikes = aligned(:, cluster_filter, :);
            peaks = all_peaks(:, cluster_filter);
            % Set up the representative wire for the cluster
            for k=1:num_of_channels
                % Set up the representative wire for the cluster
                [~, max_wire] = max(peaks, [], 1);
                poss_wires = unique(max_wire);
                n = histc(max_wire, poss_wires);
                [~, max_n] = max(n);
                compare_wire = poss_wires(max_n);
                peaks(compare_wire,:) = nan;
                the_wf  =shiftdim(spikes(compare_wire, :, :));
                if size(the_wf,2) ~= size(aligned,3) && size(the_wf,1) == size(aligned,3)
                    the_wf = the_wf.';
                end
                mean_waveform = mean(the_wf, 1);
                % disp(size(mean_waveform))
                mean_waveform = mean_waveform - mean(mean_waveform);
                % disp(size(mean_waveform))
                mean_waveform_cell_array{j,k} = mean_waveform;
            end
        end
        for k=1:num_of_channels
            current_data.("mean_waveform_rep_wire_"+string(k)) = mean_waveform_cell_array(:,k);
        end
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