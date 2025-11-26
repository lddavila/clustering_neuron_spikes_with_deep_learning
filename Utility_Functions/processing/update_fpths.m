function [blind_pass_table] = update_fpths(blind_pass_table,config)
%this function is used to update any element in the blind pass table which
%has a fp
%this allows for most functions to still work provided that they have the
%same datasets on their machine 

%define the blind_pass_table variables with file paths
file_path_names = ["fp_to_aligned","fp_to_cleaned_clusters","fp_to_reg_timestamps","fp_to_reg_timestamps_of_the_spikes","fp_to_sorted_spike_windows_after_purges","fp_to_timestamps_rtvals"];

for i=1:length(file_path_names)
    %take 1 example of the filepath for the current file and find the base
    %file path
    current_example = blind_pass_table{1,file_path_names(i)};

    %if the current example already hass hte base file path then we presume
    %that it doesn't need to be replaced and continue
    if contains(current_example,config.base_file_path,"IgnoreCase",true)
        continue;
    end

    og_fpth_is_linux = false;
    starts_with_slash = false;
    %check if the current example uses '/' (linux) or '/' windows
    if contains(current_example,"/")
        split_example = split(current_example,"/");
        og_fpth_is_linux = true;
    else
        split_example = split(current_example,"\");
    end
    
    %now navigate through the split example until you find the base file
    %path
    counter = 1;
    while counter <= length(split_example) && split_example(counter)~="clustering_neuron_spikes_with_deep_learning"
        if counter==1 && split_example(counter)==" "
            starts_with_slash=true;
        end
        counter = counter+1;
    end

    %now you can combine everything before the split split_example and
    %replace this in the current variable 
    if og_fpth_is_linux && starts_with_slash
        part_to_replace = strjoin(split_example(1:counter),"/");
        part_to_replace = strjoin("/",part_to_replace);
    elseif og_fpth_is_linux
        part_to_replace = strjoin(split_example(1:counter),"/");
    elseif starts_with_slash
        part_to_replace = strjoin(split_example(1:counter),"\");
        part_to_replace = strjoin("\",part_to_replace);
    else
        part_to_replace = strjoin(split_example(1:counter),"\");
    end

    % after_base = strjoin(split_example(counter:end),filesep);

    %now replace what's in the blind pass_table
    if og_fpth_is_linux
        blind_pass_table.(file_path_names(i)) = strrep(strrep(blind_pass_table{:,file_path_names(i)},part_to_replace,config.base_file_path),"/",filesep);
    else
        blind_pass_table.(file_path_names(i)) = strrep(blind_pass_table{:,file_path_names(i)},part_to_replace,config.base_file_path);
    end
end

end