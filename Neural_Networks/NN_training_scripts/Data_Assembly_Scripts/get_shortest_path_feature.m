function [shortest_path_col] = get_shortest_path_feature(blind_pass_table,comparisons,make_plot,probe_graph,x,y)


%extract the channels for each tetrode
grades = vertcat(blind_pass_table{:,"grades"}{:});
channel_list = cell2mat(grades(:,49));

shortest_path_col = zeros(size(comparisons,1),1);

%for each
for i=1:size(comparisons,1)

    % Now plot the graph using these true coordinates
    %figure;
    if i==1 && make_plot
        p = plot(probe_graph, ...
            'XData', x, ...
            'YData', y, ...
            'NodeLabel', {}, ...
            'MarkerSize', 4);
        axis equal; box on;
        xlabel('x (\mum)'); ylabel('y (\mum)');
        title('Probe graph with physical coordinates');
    end
    left_channels = channel_list(comparisons(i,1),:);
    right_channels = channel_list(comparisons(i,2),:);

    %share all the same channels and thus the distanc is 0
    if all(any(left_channels==right_channels.'))
        continue
    end

    %when they don't share all the same channels then we have to find the
    %average distance between all of the channels
    matrix_of_distances = zeros(length(left_channels),length(right_channels));
    for j=1:length(left_channels)
        for k=1:length(right_channels)
            [~,matrix_of_distances(j,k)] =shortestpath(probe_graph,left_channels(j),right_channels(k));
        end
    end
    shortest_path_col(i) = mean(matrix_of_distances,"all");
    fprintf("%i/%i avg dist: %.2f\n",i,size(comparisons,1),shortest_path_col(i));
end


end