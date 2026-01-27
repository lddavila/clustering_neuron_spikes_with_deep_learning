function [] = compare_ic_cutting_to_default(default_example,ic_example,config)

default_example = update_fpths(default_example,config);
ic_example = update_fpths(ic_example,config);
default_aligned = importdata(default_example{1,"fp_to_aligned"}).aligned;
ic_aligned = importdata(ic_example{1,"fp_to_aligned"}).aligned;


ic_cluster_idx = ic_example{1,"cluster_idx"}{1};
default_cluster_idx = default_example{1,"cluster_idx"}{1};

figure
plot(squeeze(ic_aligned(1,ic_cluster_idx,:)).')
title("Cluster according to IronClust")
disp("IronClust Result")
disp(ic_example(:,["Z Score","Tetrode","Cluster","Max_Overlap_Unit","accuracy"]))

figure
plot(squeeze(default_aligned(1,default_cluster_idx,:)).');
title("Cluster according to default")
disp("Default Result")
disp(default_example(:,["Z Score","Tetrode","Cluster","Max_Overlap_Unit","accuracy"]))
end