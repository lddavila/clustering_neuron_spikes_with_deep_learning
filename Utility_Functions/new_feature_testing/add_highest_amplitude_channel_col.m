function [blind_pass_table] = add_highest_amplitude_channel_col(blind_pass_table)
split_bp_table = slice_table_for_parallel_processing(blind_pass_table,"fp_to_aligned");
parfor i=1:length(split_bp_table)
    current_data = split_bp_table{i};
    aligned = load(current_data{1,"fp_to_aligned"});
    aligned = aligned.data_to_save;

    peaks = get_peaks(aligned,true);
    valleys = get_peaks(aligned * -1,true);
    which_channel = nan(height(current_data),1);
    which_channel_2 = nan(height(current_data),1);
    spike_amp_arr = nan(height(current_data),1);
    spike_amp_2 = nan(height(current_data),1);
    for j=1:height(current_data)
        cluster_peaks = peaks(:,current_data{j,"cluster_idx"}{1});
        cluster_valleys = valleys(:,current_data{j,"cluster_idx"}{1});
        spike_amp = abs(cluster_peaks)%- cluster_valleys);
        mean_spike_amp = mean(spike_amp,2);
        channels = current_data{j,"channels"}{1};
        [m_v,m_i] = max(mean_spike_amp);
        mean_spike_amp(m_i) = 0;
        which_channel(j) = channels(m_i);
        spike_amp_arr(j) = m_v; 
        [m_v,m_i] = max(mean_spike_amp);
        which_channel_2(j) = channels(m_i);
        spike_amp_2(j) = m_v;

    end
    current_data.ch_with_largest_pk_amp = which_channel;
    current_data.ch_with_largest_pk_amp_2 = which_channel_2;
    current_data.spike_amp = spike_amp_arr;
    current_data.spike_amp_2 = spike_amp_2;
    split_bp_table{i} = current_data;
end
blind_pass_table = vertcat(split_bp_table{:});
end