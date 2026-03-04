%edited by Luis David Davila and Alexander Friedman
function the_dir_path = kyle_dir(the_filenames)
    [basepath, ~, ~] = fileparts(the_filenames.full_dir);
    [~, rat_name, ~] = fileparts(basepath);
    the_dir_path = regexprep(rat_name, '^(k\d+).*', '$1');
end