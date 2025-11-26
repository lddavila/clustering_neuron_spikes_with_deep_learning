function [rep_wires,channels] = get_rep_wire_for_every_cluster(blind_pass_table)
grades = vertcat(blind_pass_table{:,"grades"}{:});
channels = cell2mat(grades(:,49));
rep_wire_idx = cell2mat(grades(:,42));
rep_wires = arrayfun(@(i) channels(i, rep_wire_idx(i)), 1:size(channels,1))';

end