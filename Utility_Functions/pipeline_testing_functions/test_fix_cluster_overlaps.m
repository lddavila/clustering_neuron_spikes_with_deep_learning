%%
load("E:\clustering_neuron_spikes_with_deep_learning\Data\test_fix_cluster_overlaps_struct.mat","test_fix_cluster_overlaps_struct");
%%
the_source = test_fix_cluster_overlaps_struct.the_source;
the_cf = test_fix_cluster_overlaps_struct.the_cf;
the_config = test_fix_cluster_overlaps_struct.the_config;
the_full_config = test_fix_cluster_overlaps_struct.the_full_config;

%% 
fix_cluster_overlaps(the_source, the_cf, the_config,the_full_config)