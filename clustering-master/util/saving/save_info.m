function save_info(filename, grades, final_grades, confidence, means, orig_filename)
%SAVE_INFO Saves information about the tetrode and clustering
    save(filename, 'grades', 'final_grades', 'confidence', 'means', 'orig_filename')
end