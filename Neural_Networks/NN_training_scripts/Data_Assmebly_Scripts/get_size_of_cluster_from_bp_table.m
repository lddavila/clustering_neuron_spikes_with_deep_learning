function [size_of_cluster] = get_size_of_cluster_from_bp_table(blind_pass_table)
size_of_cluster = cell2mat(cellfun(@size,blind_pass_table{:,"timestamps"},'UniformOutput',false));
size_of_cluster = size_of_cluster(:,1);
end