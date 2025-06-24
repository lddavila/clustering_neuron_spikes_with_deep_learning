function [base_filepath] = get_base_filepath()
current_directory = pwd;
split_directory = split(current_directory,filesep);
while split_directory{end}~="clustering_neuron_spikes_with_deep_learning"
    split_directory = split_directory(1:end-1);
end
base_filepath = strjoin(split_directory,filesep);
end