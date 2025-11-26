function xy = get_probe_xy()
%GET_NEUROPIXELS384_XY  Return 384×2 Neuropixels 1.0 site coordinates (in µm).
%
%   Output:
%     xy(i,1) = x-coordinate of site i
%     xy(i,2) = y-coordinate of site i

%the important part is ensuring that the coordinates are consistent in
%relaiton to each other not necessarily their positions on the phycal probe

%the row pitch is 20 µm
%the column pitch is 16µm

%let us assume that channel 1 will act as our (0,0) or origin
%we'll use this to build the first column
col_1_x = zeros(96,1);
col_1_y = zeros(96,1);
for i=2:size(col_1_x,1)
    col_1_y(i) = col_1_y(i-1)+40;
end

col_2_x = zeros(96,1) + 16;
col_2_y = zeros(96,1) + 20;
for i=2:size(col_2_x,1)
    col_2_y(i) = col_2_y(i-1)+40;
end

col_3_x = zeros(96,1) +col_2_x(1)+ 16;
col_3_y = zeros(96,1);
for i=2:size(col_3_x,1)
    col_3_y(i) = col_3_y(i-1)+40;
end

col_4_x = zeros(96,1) +col_3_x(1)+ 16;
col_4_y = zeros(96,1)+20;
for i=2:size(col_4_x,1)
    col_4_y(i) = col_4_y(i-1)+40;
end

xy = [[col_1_x;col_2_x;col_3_x;col_4_x],[col_1_y;col_2_y;col_3_y;col_4_y]];

end
