function [] = par_save(file_save_name,data_to_save)
file_save_name_as_char = char(file_save_name);
if ~strcmp(file_save_name_as_char(end-3:end), '.mat') %if it's missing the .mat file extension add it yourself
    file_save_name = file_save_name+".mat";
end
twoGB_in_bytes = 2 * 1024^3; % 2 * (1024 * 1024 * 1024) %used to check for larger files as expected in real simulations
data_to_save_data = whos("data_to_save");
%check if the file is too large to save in normal format
if data_to_save_data.bytes >= twoGB_in_bytes
    save(file_save_name,"data_to_save", '-v7.3', '-nocompression');
else
    save(file_save_name,"data_to_save");
end

end