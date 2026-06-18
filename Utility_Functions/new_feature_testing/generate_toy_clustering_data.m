function [cell_array_of_gt_idxs,cell_array_of_cores,X,waveform_tensor] = generate_toy_clustering_data(total_dims,num_points,num_clusters,verify_with_2d_plots,config,varargin)
%the purpose of this function is to create a simulated "peaks" data set
%which will be used to test our theory of using the generic clustering
%algorithm (based on peaks) to find  the dimensions which represent the
%"cores" of the cluster
%then to see if we can identify clusters that have overlapping/similar
%dimensions and see build a kind of map of the n-dimensional space which
%connects all of the clusters in relation to each other
%this may have some uses in Machine Learning applications
rng('default') % For reproducibility
% fs = 30000;
% waveform_ms = 2.0;

%get waveform templates
%                                  make_cluster_dim_gmonopuls_templates(num_clusters,total_dims,fs,waveform_ms)

cluster_templates = make_cluster_dim_gmonopuls_templates(num_clusters,total_dims);
%cluster templates is a 3d array
%size(cluster_templates) = #clusters X #dimensions X #datapoints

% total_dims = 100;
% informative_dims = 5;
% num_points = 300;
if isempty(varargin)
    dir_to_save_data = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"toy_data"));
else
    dir_to_save_data =varargin{1} ;
end

save_name = fullfile(dir_to_save_data,"toy_data.mat");
if ~isfile(save_name)
    % Initialize the matrix with background uniform noise
    mu = 20; %normal random background noise of extracellular recordings
    sigma = 100; %deviation which we may expect from actual spikes which will occur sporaddically
    X = normrnd(mu,sigma,num_points,total_dims); %represents the peaks that might be found when running detection on raw extracellular recordings

    %insert the clusters randomly into the high dimensional data
    cell_array_of_gt_idxs = cell(num_clusters,1);
    cell_array_of_cores = cell(num_clusters,1);
    spike_cluster_labels = zeros(num_points,1);
    noise_sigma = 0.05 * median(abs(X(:)));
    for i=1:num_clusters
        if i==1
            connect_to_other_cluster = false; %cannot be connected if you are the first cluster being created
        else
            connect_to_other_cluster = rand() < 0.8; %probability of the cluster being connected to an already existing cluster, we are biasing connection since we expect there to be more connected clusters than not
        end

        num_vis_dim = randperm(7,1) + 1;%randomly select # of dimensions that the cluster will be visible on always ensure its at least 2 by adding 1
        if connect_to_other_cluster
            rand_conn_cluster = randperm(i-1,1);%choose another cluster at random to connect to
            rand_connectable_dims = cell_array_of_cores{rand_conn_cluster};   %get dimensions that appear in the randomly connected cluster
            max_shared_dims = min(floor(num_vis_dim/2),length(rand_connectable_dims));
            rand_num_dims_to_connect = randi(max_shared_dims); %pick up to 1/2 of dimensions in current cluster to replace with dimensions from the connected cluster
            rand_dims_to_connect = rand_connectable_dims(randperm(length(rand_connectable_dims),rand_num_dims_to_connect)); %randomly index the dimensions which the clusters will be connected to
            still_usable_dims = setdiff(1:total_dims,rand_dims_to_connect); %see which dimensions should not be added back in
            core_dims = [still_usable_dims(randperm(length(still_usable_dims),num_vis_dim-length(rand_dims_to_connect))),rand_dims_to_connect];%get remaining dimensions
        else
            core_dims = randperm(total_dims,num_vis_dim);
        end

        cell_array_of_cores{i} = core_dims;

        separation = 2 + 4*rand(1,num_vis_dim);  % distance from background in SD units
        direction = 2*randi([0,1],1,num_vis_dim) - 1;

        cluster_center = mu + direction .* separation .* sigma;

        cluster_spread_fraction = 0.2 + 0.3*rand;
        cluster_sigma = sigma * cluster_spread_fraction;


        min_cluster_size = 100;%max(10,round(0.01*num_points));
        max_cluster_size = 1000;%max(min_cluster_size,round(0.02*num_points));
        cluster_size = randi([min_cluster_size,max_cluster_size]);
        % cluster_size = randi([min_cluster_size,num_points]); %randomly select cluster size
        available_spike_idxs = find(spike_cluster_labels == 0);

        if isempty(available_spike_idxs)
            warning("No unassigned spikes remain. Stopping cluster insertion early. Created "+string(i)+" clusters instead");
            break
        end

        cluster_size = min(cluster_size,length(available_spike_idxs));

        idxs_of_random_spikes = available_spike_idxs(randperm(length(available_spike_idxs),cluster_size)); %select the random rows in our data which will be a part of the cluster
        X(idxs_of_random_spikes,core_dims) = cluster_center +cluster_sigma .* randn(length(idxs_of_random_spikes),num_vis_dim); % alter the data to create the cluster
        cell_array_of_gt_idxs{i} = idxs_of_random_spikes; %preserve the ground truth idxs
        spike_cluster_labels(idxs_of_random_spikes) = i;

    end



    waveform_tensor = create_waveforms_with_cluster_dim_templates(X,spike_cluster_labels,cluster_templates,noise_sigma);

    waveform_tensor = permute(waveform_tensor,[3,1,2]);
    waveform_tensor = interpolate_spikes(waveform_tensor,config);
    data_struct = struct();
    data_struct.aligned = waveform_tensor;
    data_struct.X = X;
    data_struct.gt_idxs = cell_array_of_gt_idxs;
    data_struct.cores = cell_array_of_cores;
    par_save(save_name,data_struct);
else
    data_struct = importdata(save_name);
    waveform_tensor = data_struct.aligned;
    X = data_struct.X;
    cell_array_of_gt_idxs = data_struct.gt_idxs;
    cell_array_of_cores = data_struct.cores ;
end

if verify_with_2d_plots
    num_clusters = length(cell_array_of_cores);

    core_matrix = false(num_clusters,total_dims);

    for cluster_idx = 1:num_clusters
        core_matrix(cluster_idx,cell_array_of_cores{cluster_idx}) = true;
    end

    figure;
    imagesc(core_matrix);
    colormap(gray);

    xlabel("Dimension");
    ylabel("Cluster");
    title("Cluster Core Dimensions");

    yticks(1:num_clusters);
    colorbar;
    row_order = optimalleaforder( ...
        linkage(pdist(double(core_matrix),"jaccard"),"average"), ...
        pdist(double(core_matrix),"jaccard"));

    column_order = optimalleaforder( ...
        linkage(pdist(double(core_matrix'),"jaccard"),"average"), ...
        pdist(double(core_matrix'),"jaccard"));

    figure;
    imagesc(core_matrix(row_order,column_order));

    xlabel("Reordered Dimension");
    ylabel("Reordered Cluster");
    title("Cluster Core-Dimension Structure");
end
end