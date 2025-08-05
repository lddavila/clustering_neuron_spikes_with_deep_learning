function [] = par_save(file_save_name,data_to_save)
file_save_name_as_char = char(file_save_name);
if ~strcmp(file_save_name_as_char(end-3:end), '.mat')
    file_save_name = file_save_name+".mat";
end
    save(file_save_name,"data_to_save");
end