function [old_peaks,only_new_peaks] = assemble_new_tetrode_peaks_and_pcs(blind_pass_table,new_peaks,new_pot_dims)
old_peaks = cell(height(blind_pass_table),1);
only_new_peaks = cell(height(blind_pass_table),1);



for i=1:length(new_peaks)
    current_candidate_peaks = new_peaks{i};
    ones_that_are_empty = cellfun(@isempty,current_candidate_peaks);
    new_assembled_peaks = [];
    new_channels = new_pot_dims{i}.';
    for j = 1:length(current_candidate_peaks)
        fprintf("i: %i j: %i\n",i,j)
        if i==373 && j==4
            disp("Case where it errors")
        end
        if isempty(current_candidate_peaks{j})
            continue;
        end

        un_edited = abs(current_candidate_peaks{j});

        if isempty(new_assembled_peaks)
            new_assembled_peaks = un_edited;
        else
            new_assembled_peaks = [new_assembled_peaks; un_edited(end,:)];
        end
    end
    if isempty(new_assembled_peaks)
        continue;
    end
    [~, peakpcs] = pca(new_assembled_peaks.');
    pc1 = peakpcs(:, 1);
    pc2 = peakpcs(:, 2);
    channels = {[string(blind_pass_table{i,"channels"}{1}),string(new_channels),"pc1","pc2"]};
    local_peaks = [new_assembled_peaks.',pc1,pc2];
    old_peaks{i} = local_peaks(:,1:length(blind_pass_table{i,"channels"}{1}));

    only_new_peaks{i} =local_peaks(:,length(blind_pass_table{i,"channels"}{1})+1:size(local_peaks,2)-2);
    % if ~isempty(old_peaks{i})
    %     general_peak_plotting_function(local_peaks.',spikesort_config,'what_kind_of_data','peaks','channels',channels,'cluster_idx',blind_pass_table{i,"cluster_idx"},'pause_on_each_plot',false)
    % end
end
end