%% import the necessary data
load("E:\clustering_neuron_spikes_with_deep_learning\Data\test_remove_bad_clusters_struct.mat","test_remove_bad_clusters_struct");
aligned = test_remove_bad_clusters_struct.aligned;
tvals = test_remove_bad_clusters_struct.tvals;
refined_clusters = test_remove_bad_clusters_struct.refined_clusters;
config = test_remove_bad_clusters_struct.config;
ir = test_remove_bad_clusters_struct.ir;

%% now test the function independently
close all;
good_filt = remove_bad_clusters(aligned, refined_clusters, ir, tvals, config);