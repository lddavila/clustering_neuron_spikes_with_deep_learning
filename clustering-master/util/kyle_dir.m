function dir_path = kyle_dir(filenames)
    [basepath, ~, ~] = fileparts(filenames.full_dir);
    [~, rat_name, ~] = fileparts(basepath);
    dir_path = regexprep(rat_name, '^(k\d+).*', '$1');
end