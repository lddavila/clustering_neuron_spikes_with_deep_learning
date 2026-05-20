%my assumption is that we can completely avoid multiple versions of the
%aligned files by just saving the one which should be the superset of all
%the other aligned files
%this is because in theory the only thing multiplier changes is the which
%spikes work

number_of_tetrodes = 1:10;
assumption_violations = 0;
for j=1:length(number_of_tetrodes)
    list_of_aligned_files = ["E:\new_ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\initial_pass_results min multiplier 1\t"+string(number_of_tetrodes(j))+" aligned.mat",...
        "E:\new_ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\initial_pass_results min multiplier 2\t"+string(number_of_tetrodes(j))+" aligned.mat",...
        "E:\new_ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\initial_pass_results min multiplier 3\t"+string(number_of_tetrodes(j))+" aligned.mat",...
        "E:\new_ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\initial_pass_results min multiplier 4\t"+string(number_of_tetrodes(j))+" aligned.mat",...
        "E:\new_ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\initial_pass_results min multiplier 5\t"+string(number_of_tetrodes(j))+" aligned.mat",...
        "E:\new_ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\initial_pass_results min multiplier 6\t"+string(number_of_tetrodes(j))+" aligned.mat",...
        "E:\new_ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\initial_pass_results min multiplier 7\t"+string(number_of_tetrodes(j))+" aligned.mat",...
        "E:\new_ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\initial_pass_results min multiplier 8\t"+string(number_of_tetrodes(j))+" aligned.mat",...
        "E:\new_ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\initial_pass_results min multiplier 9\t"+string(number_of_tetrodes(j))+" aligned.mat",...
        "E:\new_ic_10_600Neuron300SecondRecordingWithLevel10Noise_4_channels\initial_pass_results min multiplier 10\t"+string(number_of_tetrodes(j))+" aligned.mat"];


    cell_array_of_aligned = cell(length(list_of_aligned_files),1);
    for i=1:length(list_of_aligned_files)
        aligned = load(list_of_aligned_files(i));
        aligned = aligned.data_to_save;
        cell_array_of_aligned{i} = aligned.aligned;
        if i~=1
            if size(cell_array_of_aligned{i},2) > size(cell_array_of_aligned{i-1},2)
                assumption_violations = assumption_violations+1;
            end
        end
        
        
        

    end

    disp(cell_array_of_aligned);
end

disp("Number of violations")
disp(assumption_violations)
%unfortunately while aligned does follow the superset schema the cluster
%because the aligned data set is different the cluster idxs are broken
%the clusters produced with aligned_1 have idxs based on the aligned_1's
%data set
%the clusters produced with aligned_2 have idxs based on the aligned_2's
%dataset
%so the cluster 2 idxs may be pointing to some/all of the same spikes as
%the cluster 1 idxs, but they index different data
%there needs to be some way to map the clusters back to the original
%aligned data set