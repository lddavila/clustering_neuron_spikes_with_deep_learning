function G = get_graph_rep_of_probe_map()
    number_of_rows = 96;
    number_of_cols = 4;

    % Build columns (zeros on the “empty pads”)
    col_1 = []; for i=96:-1:1,   col_1 = [col_1; 0;   i];   end
    col_2 = []; for i=192:-1:97, col_2 = [col_2; i;   0];   end
    col_3 = []; for i=288:-1:193,col_3 = [col_3; 0;   i];   end
    col_4 = []; for i=384:-1:289,col_4 = [col_4; i;   0];   end
    probe_map_matrix = [col_1,col_2,col_3,col_4];  % 192 x 4

    max_id = max(probe_map_matrix,[],'all');
    dict = containers.Map('KeyType','double','ValueType','any');

    for row = 1:size(probe_map_matrix,1)
        for col = 1:number_of_cols
            cur = probe_map_matrix(row,col);
            if cur==0, continue; end
            nbrs = [];

            % vertical
            if row-2 >= 1,                     nbrs(end+1) = probe_map_matrix(row-2,col); end
            if row+2 <= size(probe_map_matrix,1), nbrs(end+1) = probe_map_matrix(row+2,col); end
            % horizontal (skip empty pad column)
            if col-2 >= 1,                     nbrs(end+1) = probe_map_matrix(row,col-2); end
            if col+2 <= number_of_cols,        nbrs(end+1) = probe_map_matrix(row,col+2); end
            % diagonals (one row, one column)
            if row-1 >= 1 && col-1 >= 1,       nbrs(end+1) = probe_map_matrix(row-1,col-1); end
            if row+1 <= size(probe_map_matrix,1) && col-1 >= 1
                                               nbrs(end+1) = probe_map_matrix(row+1,col-1); end
            if row-1 >= 1 && col+1 <= number_of_cols
                                               nbrs(end+1) = probe_map_matrix(row-1,col+1); end
            if row+1 <= size(probe_map_matrix,1) && col+1 <= number_of_cols
                                               nbrs(end+1) = probe_map_matrix(row+1,col+1); end

            % clean: drop zeros & self, unique
            nbrs = unique(nbrs(nbrs>0 & nbrs~=cur));
            dict(cur) = nbrs;
        end
    end

    % --- Build edge list (numeric vectors, same length) ---
    ks = cell2mat(keys(dict).');      % sources (unique nodes)
    edges = [];                        % [s t] rows
    for i = 1:numel(ks)
        s = ks(i);
        vs = dict(s);
        if ~isempty(vs)
            edges = [edges; [repmat(s,numel(vs),1) vs(:)]];
        end
    end
    % undirected: remove duplicates like (u,v) and (v,u)
    edges = sort(edges,2);
    edges = unique(edges,'rows');

    % Node names
    node_names = arrayfun(@(k) sprintf('C%d',k), 1:max_id, 'UniformOutput', false);

    % Create graph
    G = graph(edges(:,1), edges(:,2), [], node_names);

    figure;
    row_pitch = 20;     % µm vertical spacing
    col_pitch = 40;     % µm horizontal spacing

    [x, y] = meshgrid(1:number_of_cols, 1:number_of_rows);
    x = x(:) * col_pitch;
    y = flipud(y(:)) * row_pitch;   % flip so row 1 is at top
    coords = [x, y];
    coords = coords(1:numnodes(G), :);
    plot(G, ...
        'XData', coords(:,1), ...
        'YData', coords(:,2), ...
        'NodeLabel', {}, ...
        'MarkerSize', 3);
    axis equal
    title('Physical Probe Layout');
    xlabel('Column (µm)');
    ylabel('Depth (µm)');
end
