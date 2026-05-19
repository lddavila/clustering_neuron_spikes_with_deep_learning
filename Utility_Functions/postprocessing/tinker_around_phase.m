function [] = tinker_around_phase(blind_pass_table,config,varargin)
%the "tinkering_around_phase" is a method after cluster creation that we
%use to try and enhance clustering by finding the ideal channels to see
%each cluster
%this is necessary because a cluster that is impossible to separate with
%the current tetrode MIGHT be seperable if we try adding/removing
%dimensions
%the question should then logically be what other channels should we
%add/remove
%luckily we already have our group or dont neural network ensemble
%this can tell us with a high degree of likelihood what clusters represent
%the same neuron regardless of whether they appear on the same channels or
%not 
%once the groups are formed we can then try to formulate which dimensions
%form the best representation of the cluster
%we'll probably try doing this based on either a neural network which uses
%our grades or a neural network which is trained to identify cluster splits
%when recombining (this neural network doesn't currently exist, but I'm
%WORKING ON IT!)

% if ~isfile(blind_pass_table{1,"fp_to_aligned"})
%     blind_pass_table = update_fpths(blind_pass_table,config);
% end

%first get the grouped clusters
if isempty(varargin)
    grouped_clusters = simple_grouping_parallel_ensemble(blind_pass_table,config,false);

else
    grouped_clusters = varargin{1};
end

%with the groups assembled we can then try to find alternate dimensions
%within each group to try and get the ideal configuration per neuron

for i=1:length(grouped_clusters)
    current_group = grouped_clusters{i};
    unique_list_of_tetrodes = unique(current_group.Tetrode);
    unique_tetrode_nums = str2double(strrep(unique_list_of_tetrodes,"t",""));
    tetrode_channels = config.ART_TETR_ARRAY(unique_tetrode_nums,:);


end

end