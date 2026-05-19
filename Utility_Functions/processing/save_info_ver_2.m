function save_info_ver_2(filename, orig_filename,timestamps,r_tvals,cleaned_clusters)
%SAVE_INFO Saves information about the tetrode and clustering
    save(filename, 'orig_filename',"timestamps","r_tvals","cleaned_clusters");
end