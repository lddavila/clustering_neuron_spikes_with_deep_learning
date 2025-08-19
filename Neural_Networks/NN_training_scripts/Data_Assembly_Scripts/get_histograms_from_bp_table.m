function [all_histograms_as_cell_array] = get_histograms_from_bp_table(blind_pass_table)
all_histograms = vertcat(blind_pass_table{:,"grades"}{:});
all_histograms = all_histograms(:,64);
all_histograms_as_cell_array = cell(1,size(all_histograms{1},1));
for i=1:size(all_histograms,1)
    for j=1:size(all_histograms{i},1)
        all_histograms_as_cell_array{i,j} = all_histograms{i}(j,:);
    end
end
end