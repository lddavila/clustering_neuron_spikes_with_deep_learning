function [old_peaks,only_new_peaks] = assemble_new_tetrode_peaks_and_pcs(blind_pass_table,new_peaks,new_pot_dims)
old_peaks = cell(height(blind_pass_table),1);
only_new_peaks = cell(height(blind_pass_table),1);
for i=1:length(new_peaks)
    current_candidate_peaks = new_peaks{i};
    ones_that_are_empty = cellfun(@isempty,current_candidate_peaks);
    new_assembled_peaks = [];
    new_channels = new_pot_dims{i}.';
    for j=1:length(current_candidate_peaks)
        
        if ones_that_are_empty(j)
            continue;
        end
        if j==1 || isempty(new_assembled_peaks)
            new_assembled_peaks = abs(current_candidate_peaks{j});
        else
            un_edited = abs(current_candidate_peaks{j});
            % peaks_to_add = current_candidate_peaks{j};
            new_assembled_peaks = [new_assembled_peaks;un_edited(end,:)];
        end
    end
    [~, peakpcs] = pca(new_assembled_peaks.');
    pc1 = peakpcs(:, 1);
    pc2 = peakpcs(:, 2);
    channels = {[string(blind_pass_table{i,"channels"}{1}),string(new_channels),"pc1","pc2"]};
    local_peaks = [new_assembled_peaks.',pc1,pc2];
    old_peaks{i} = local_peaks(1:length(blind_pass_table{i,"channels"}{1}));

    only_new_peaks =local_peaks(length(blind_pass_table{i,"channels"}{1}):end);
    if ~isempty(old_peaks{i})
        general_peak_plotting_function(local_peaks.',spikesort_config,'what_kind_of_data','peaks','channels',channels,'cluster_idx',blind_pass_table{i,"cluster_idx"},'pause_on_each_plot',true)
    end
end
end