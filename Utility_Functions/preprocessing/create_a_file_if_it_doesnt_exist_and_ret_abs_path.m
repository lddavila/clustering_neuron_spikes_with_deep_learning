function [file_you_want_to_create_abs] = create_a_file_if_it_doesnt_exist_and_ret_abs_path(file_you_want_to_create)
if ~exist(file_you_want_to_create,"dir")
    mkdir(file_you_want_to_create)
    home_dir = cd(file_you_want_to_create);
    file_you_want_to_create_abs = cd(home_dir);
else
    home_dir = cd(file_you_want_to_create);
    file_you_want_to_create_abs = cd(home_dir);
end

end