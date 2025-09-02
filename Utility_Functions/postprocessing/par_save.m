function [] = par_save(file_save_name,data_to_save)
file_save_name_as_char = char(file_save_name);
if ~strcmp(file_save_name_as_char(end-3:end), '.mat') %if it's missing the .mat file extension add it yourself
    file_save_name = file_save_name+".mat";
end

%check if the file is too large to save in normal format


save(file_save_name,"data_to_save", '-v7.3', '-nocompression');


end