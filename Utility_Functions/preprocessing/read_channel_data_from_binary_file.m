function [channel_data] = read_channel_data_from_binary_file(dir_with_binary_file,current_channel)
%look for all files in the directory with binary files
list_of_files = struct2table(dir(dir_with_binary_file));
list_of_files = string(list_of_files{:,"name"});
%ensure that we have a binary file and a paralms file
if any([~ismember("sim.imec0.ap_params.npz",list_of_files),~ismember("sim.imec0.ap.meta",list_of_files),~ismember("sim.imec0.ap.bin",list_of_files)])
    channel_data = [];
    disp("The required files")
    disp("sim.imec0.ap_params.npz")
    disp("sim.imec0.ap.meta")
    disp("sim.imec0.ap.bin")
    disp("Weren't found in the specified directory please check to ensure you specified the correct directory.")
    return;
end
%create a dictionary which will have all the information we need to read
%the binary file

binary_file_dict =  containers.Map();
binary_file_dict("n_Saved_Chans") = 0;
S = jsondecode(fullfile(dir_with_binary_file,"sim.imec0.ap.ch"));   % path to your .ch
binary_file_dict("sample_rate")= double(S.sample_rate);             % sampling rate (Hz)
binary_file_dict("dtype")  = string(S.dtype);                   % e.g., "int16"
binary_file_dict("shape")  = double(S.shape(:)).';              % [n_samples, n_channels]

end