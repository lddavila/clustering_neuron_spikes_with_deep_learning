function [] = check_accuracies_of_other_structs()
all_files = struct2table(dir("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\ch_bttr_through_dropping\*.mat"));
for i=1:height(all_files)
    current_struct = importdata(fullfile(all_files{i,"folder"}{1},all_files{i,"name"}{1}));
    try
        disp(fullfile(all_files{i,"name"}{1} +" accuracy:"+string(current_struct.baseline_test_accuracy)))
    catch
        disp(fullfile(all_files{i,"name"}{1} +" accuracy:"+string(current_struct.current_accuracy)))
    end
end

end