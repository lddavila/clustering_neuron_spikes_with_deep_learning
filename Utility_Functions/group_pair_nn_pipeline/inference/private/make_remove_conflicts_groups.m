function groups = make_remove_conflicts_groups(merge_matrix)
%MAKE_REMOVE_CONFLICTS_GROUPS Make conservative groups from a merge matrix.
%
% A cluster is marked as a conflict when it links to two neighbors that do
% not link to each other. Conflict clusters become singleton groups. The
% remaining clusters are grouped by connected components.

number_of_clusters = size(merge_matrix, 1);
if size(merge_matrix, 2) ~= number_of_clusters
    error("The ensemble merge matrix must be square.");
end
if number_of_clusters == 0
    groups = cell(0, 1);
    return
end
if number_of_clusters == 1
    groups = {1};
    return
end

links = logical(merge_matrix);
links(1:number_of_clusters + 1:end) = false;
is_conflict = false(number_of_clusters, 1);

for cluster_id = 1:number_of_clusters
    neighbors = find(links(cluster_id, :));
    if numel(neighbors) < 2
        continue
    end

    links_between_neighbors = links(neighbors, neighbors);
    links_between_neighbors(1:numel(neighbors) + 1:end) = true;
    is_conflict(cluster_id) = ~all(links_between_neighbors, "all");
end

conflict_clusters = find(is_conflict);
clean_clusters = find(~is_conflict);
clean_groups = cell(0, 1);

if ~isempty(clean_clusters)
    clean_components = conncomp(graph(links(clean_clusters, clean_clusters)));
    clean_groups = cell(max(clean_components), 1);
    for group_id = 1:numel(clean_groups)
        clean_groups{group_id} = clean_clusters(clean_components == group_id);
    end
end

conflict_groups = num2cell(conflict_clusters);
groups = [clean_groups; conflict_groups];

if ~isequal(sort(vertcat(groups{:})), (1:number_of_clusters).')
    error("remove_conflicts lost or duplicated one or more clusters.");
end
end
