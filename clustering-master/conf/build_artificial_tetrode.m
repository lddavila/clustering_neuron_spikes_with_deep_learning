function [art_tetrode_array] = build_artificial_tetrode() 
art_tetrode_array = [];
channel_array = reshape(1:384,96,4);
for row_number=1:95
    for col_number = 1:3
        art_tetrode_array = [art_tetrode_array;[reshape(channel_array(row_number:row_number+1,col_number:col_number+1),1,4)]];
    end
end