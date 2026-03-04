%edited by Luis David Davila and Alexander Friedman
function save_stat(the_filename, the_stat, the_clusters_found, the_manual_gradings)
%SAVE_STAT Saves the statistics versus manual clustering
    save(the_filename, 'the_stat', 'the_clusters_found', 'the_manual_gradings')
end