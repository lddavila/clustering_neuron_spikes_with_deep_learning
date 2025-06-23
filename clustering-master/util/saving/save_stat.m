function save_stat(filename, stat, clusters_found, manual_gradings)
%SAVE_STAT Saves the statistics versus manual clustering
    save(filename, 'stat', 'clusters_found', 'manual_gradings')
end