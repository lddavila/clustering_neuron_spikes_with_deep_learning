function [] = collapse_groups(cell_array_of_cluster_groups,config,number_of_representatives_per_group)
%the goal of this function is to solve the problem of repititions aka false
%positives
%currently we have a problem of over representation in our cluster groups
%for example we produce 105 cluster groups when only 100 ground truth units
%actually exist
%originally we attempted to solve this problem by using the percentile
%feature to pick the best representation of each cluster (where best is defined by the percentile feature) group and check
%for mergability based off those best representations
%unfortunatley this caused overmerging
%so let us instead try checking for collapsible groups by looking at the
%top n best representations and ensuring they can all be merged

%step 1 will be to get the n clusters with the highest percentile from each cluster group
group_representatives = cell(number_of_representatives_per_group,1);
for i=1:length(cell_array_of_cluster_groups)
    current_data = sortrows(cell_array_of_cluster_groups{i},"Percentile",'descend');
    group_representatives{i} = current_data(1:min([size(current_data,1),number_of_representatives_per_group]),:);
end

%now that we have the representations we can check them for mergability
nn_struct = importdata(config.FP_TO_COMPLEX_MERGE_OR_DONT_NN);
nn= nn_struct.net;
for i=1:length(group_representatives)
    current_representatives = group_representatives{i};
    for j=i+1:length(group_representatives)
        compare_representatives = group_representatives{j};

    end
end

end