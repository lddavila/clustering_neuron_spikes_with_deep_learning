function [blind_pass_table] = add_isi_violation_count_col(blind_pass_table,config)
number_of_isi_violations = zeros(height(blind_pass_table),1);

% peaks = get_peaks(aligned,true);
% threshold_to_use =config.spikesort.params.GR_MAX_SHORT_ISI_PERCENT;
for i=1:height(blind_pass_table)
    cluster_1_ts = blind_pass_table{i,"timestamps"}{1};
    isi = diff(cluster_1_ts);
    number_of_isi_violations(i) = sum(isi < config.spikesort.params.GR_SHORT_ISI_LEN);

end
blind_pass_table.num_isi_violations = number_of_isi_violations;
end