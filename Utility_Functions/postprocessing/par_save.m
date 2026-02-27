function [] = par_save(file_save_name,data_to_save)
file_save_name_as_char = char(file_save_name);
if ~strcmp(file_save_name_as_char(end-3:end), '.mat') %if it's missing the .mat file extension add it yourself
    file_save_name = file_save_name+".mat";
end
%check if the file is too large to save in normal format
% Get information about the variable using whos
varInfo = whos("data_to_save");

% The size is in the 'bytes' field of the structure
varSizeInBytes = varInfo.bytes;

% Define the 2 GB limit in bytes (2 * 1024 * 1024 * 1024)
limitBytes = 1.5 * 1024^3; 

% Check if the variable size is less than the limit
isLessThan2GB = varSizeInBytes < limitBytes;
if isLessThan2GB
    save(file_save_name,"data_to_save");
else
    save(file_save_name,"data_to_save", '-v7.3', '-nocompression');
end

end