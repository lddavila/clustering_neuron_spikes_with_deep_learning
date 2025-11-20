function [groups] = reform_groups_based_on_tags(blind_pass_table)
sizes = cell2mat(cellfun(@size, blind_pass_table{:,"group_tags"}, 'UniformOutput', false));
blind_pass_table = blind_pass_table(sizes(:,2)<2,:);
unique_group_tags = unique(cell2mat(vertcat(blind_pass_table{:,"group_tags"}(:))));
groups = cell(length(unique_group_tags),1);
for i=1:length(unique_group_tags)
    groups{i} = blind_pass_table(cell2mat(vertcat(blind_pass_table{:,"group_tags"}))==unique_group_tags(i),:);
end
end