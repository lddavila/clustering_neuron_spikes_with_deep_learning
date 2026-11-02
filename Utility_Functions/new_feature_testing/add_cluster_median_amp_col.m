function [blind_pass_table] = add_cluster_median_amp_col(blind_pass_table)
sliced_bp = slice_table_for_parallel_processing(blind_pass_table,[]);
parfor i =1:length(sliced_bp)
    curr_dat = sliced_bp{i};
    curr_wf = curr_dat{1,"mean_waveform_rep_wire_1"}{1};
    curr_dat.mean_amp = curr_wf{47};
    sliced_bp{i} = curr_dat;
end
blind_pass_table = vertcat(sliced_bp{:});
end