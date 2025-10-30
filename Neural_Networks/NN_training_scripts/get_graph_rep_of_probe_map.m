function [probe_map] = get_graph_rep_of_probe_map()
%specify the number of cols/rows that are in the probe
number_of_rows = 96;
number_of_cols = 4;

%set up the cols of channels that represent the probe map
col_1 = (96:-1:1).';
just_zeros = zeros(size(col_1),1);
col_2 = (192:-1:97).' ;
col_3 = (288:-1:193).';
col_4 = (384:-1:289).';
probe_map_matrix = [];

%build a blank connection matrix
connection_matrix = zeros(number_of_rows,number_of_cols);

dictionary_of_neighbors = containers.Map('KeyType','double','ValueType','any');
for row=1:number_of_rows
    for col = 1:number_of_cols
        current_channel = probe_map_matrix(row,col);
        %add potential neighbors with conditions
        potential_neigbors = [];

        %add the neighbor directly below if not on the top row
        if row ~= 1
            potential_neigbors = [potential_neigbors,probe_map_matrix(row-1,col)];
        end

        %add the neighbor directly above if not on the last row
        if row ~=size(connection_matrix,1)
            potential_neigbors = [potential_neigbors,probe_map_matrix(row+1,col)];
        end

        %add the neighbor directly to the right if not already on the right-most col
        if col ~= size(connection_matrix,2) 
            potential_neigbors = [potential_neigbors,probe_map_matrix(row,col+1)];
        end

        %add the neighbor to the left if not already on the left-most col
        if col ~= 1
            potential_neigbors = [potential_neigbors,probe_map_matrix(row,col-1)];
        end

        dictionary_of_neighbors(current_channel) = potential_neigbors;
    end
end

%add connections to the channels directory above 
% connection_matrix()

%get node names
node_names = cell(number_of_cols * number_of_rows,1);
for i=1:length(node_names)
    node_names{i} = "C"+string(i);
end
%create the graph object 
probe_map = graph(connection_matrix,node_names);
end