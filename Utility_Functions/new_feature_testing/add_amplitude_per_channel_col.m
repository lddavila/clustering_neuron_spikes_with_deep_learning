function [blind_pass_table] = add_amplitude_per_channel_col(blind_pass_table)
split_bp_table = slice_table_for_parallel_processing(blind_pass_table,"fp_to_aligned");
for i=1:length(split_bp_table)
    current_data = split_bp_table{i};
    aligned = load(current_data{1,"fp_to_aligned"});
    aligned = aligned.data_to_save;
    peaks = get_peaks(aligned,true);
    channel_amp = cell(height(current_data),1);
    for j=1:height(current_data)
        cluster_peaks = peaks(:,current_data{j,"cluster_idx"}{1});
      
        spike_amp = abs(cluster_peaks);
        channel_amp{j} = mean(spike_amp,2).';
     
    end
    current_data.ch_amp = channel_amp;
    split_bp_table{i} = current_data;
end
blind_pass_table = vertcat(split_bp_table{:});
end