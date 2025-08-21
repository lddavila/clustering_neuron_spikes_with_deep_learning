function [all_histograms_as_cell_array] = get_histograms_from_bp_table(blind_pass_table,which_histogram_string)
which_histogram_string_split = split(which_histogram_string," ");
which_histogram = str2double(which_histogram_string_split{end});
all_histograms = vertcat(blind_pass_table{:,"grades"}{:});
all_histograms = all_histograms(:,64);
all_histograms_as_cell_array = cell2mat(cellfun(@(M) M(which_histogram,:),all_histograms,'UniformOutput',false));
end