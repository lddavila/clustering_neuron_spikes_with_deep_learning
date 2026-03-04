%edited by Luis David Davila and Alexander Friedman
function save_info(the_filename, the_grades, the_final_grades, the_confidence, the_means, the_orig_filename)
%SAVE_INFO Saves information about the tetrode and clustering
    save(the_filename, 'the_grades', 'the_final_grades', 'the_confidence', 'the_means', 'the_orig_filename')
end