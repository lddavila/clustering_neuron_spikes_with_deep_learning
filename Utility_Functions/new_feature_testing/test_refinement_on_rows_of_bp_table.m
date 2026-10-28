function [] = test_refinement_on_rows_of_bp_table(blind_pass_table,options)
arguments
    blind_pass_table table;
    options
end
    function [] = get_peaks_on_new_dimensions()
    end
%1.) Looking at a given cluster through the viewpoint of channels not included in the current cluster leads to 3 possibilities
%   1a.)  Completely split the cluster indicating to us that the single cluster may actually be multiple clusters hidden by similar peaks
%   1b.)  Cluster spread defined by the density of the cluster becoming less indicating some points that could be shaved off if done properly
%   1c.)  Cluster completely dissapears indicating that it is not visible on the new channels
%   - (1a) and (1b) tend to increase accuracy as they can remove false positives which seems to be our problem at the moment
%2.) By completely dropping dimensions we might see the following
%   2a.) The cluster completely collapses 
%   2b.) The cluster becomes smaller as spikes from those irrelevant dimensions remove themselves
end