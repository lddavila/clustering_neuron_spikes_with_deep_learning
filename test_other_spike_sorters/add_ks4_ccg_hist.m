function [blind_pass_table] = add_ks4_ccg_hist(blind_pass_table,config)
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,[]);
is_refractory = nan(size(sliced_bp_table,1),1);
is_cross_refractory =nan(size(sliced_bp_table,1),1);
for w=1:size(blind_pass_table,1)
    current_ts = sliced_bp_table{w}{1,"timestamps"}{1};
    %KS4 PYTHON IMPLEMENTATION
    % def check_CCG(st1, st2=None, nbins = 500, tbin  = 1/1000, acg_threshold=0.2,
    %               ccg_threshold=0.25):
    %     # NOTE: The default `acg_threshold=0.2` is different from the value of 0.1
    %     #       used for the Kilosort4 paper. We felt this better reflects common
    %     #       practice for determining 'good' units, but you can set
    %     #       `acg_threshold=0.1` in your run settings for stricter criteria.
    %     if st2 is None:
    %         st2 = st1.copy()
    %     K , T= compute_CCG(st1, st2, nbins = nbins, tbin = tbin)
    %     R12, Q12, Q00 = CCG_metrics(st1, st2, K, T,  nbins = nbins, tbin = tbin)
    %     is_refractory    = R12<acg_threshold  and (Q12<.2)#  or Q00<.25)
    %     cross_refractory = R12<ccg_threshold and (Q12<.05)# or Q00<.25)
    %     return is_refractory, cross_refractory, R12

    acg_threshold = config.ACG_THRESHOLD;
    ccg_threshold = config.CCG_THRESHOLD;
    t_bin = 1/1000;
    n_bins = 500;

    %compute CCG
    cluster_1_spike_ts = current_ts; %already sorted PLACEHOLDER
    cluster_2_spike_ts = current_ts; %already sorted PLACEHOLDER

    dt = n_bins * t_bin;
    T = max([max(cluster_1_spike_ts),max(cluster_2_spike_ts)] - min([cluster_1_spike_ts,cluster_2_spike_ts]));

    i_low = 1;
    i_high = 1;
    j = 1;

    K = zeros(2 *n_bins+1,1);
    while j<=length(cluster_2_spike_ts)
        while i_high <= length(cluster_1_spike_ts) && cluster_1_spike_ts(i_high) <= cluster_2_spike_ts(j)+dt
            i_high = i_high+1;
        end
        while i_low <= length(cluster_1_spike_ts) && (cluster_1_spike_ts(i_low) < cluster_2_spike_ts(j)-dt)
            i_low = i_low+1;
        end
        if i_low >= length(cluster_1_spike_ts)
            break;
        end
        for k=i_low:i_high-1
            if k==j
                continue;
            end
            i_bin = round((cluster_2_spike_ts(j) - cluster_1_spike_ts(k))/t_bin);
            K(i_bin+n_bins+1) = K(i_bin+n_bins+1)+1;
        end
        j = j+1;
        %disp("Finished while loop iteration")
    end

    % disp("Exited while loop")
    % now get CCG metrics
    i_range_1 = [1:(floor(n_bins/2)-1), floor(3*n_bins/2):(2*n_bins-1)];
    i_range_2 = n_bins-50:n_bins-11;
    i_range_3 = n_bins+11:n_bins+50;

    r_00 = sum(K(i_range_1),"all") / (length(i_range_1) * t_bin * length(cluster_1_spike_ts) * length(cluster_2_spike_ts) / T);
    r_1 = sum(K(i_range_2),"all") / (length(i_range_2) * t_bin * length(cluster_1_spike_ts) * length(cluster_2_spike_ts) / T);
    r_2 = sum(K(i_range_3),"all") / (length(i_range_3) * t_bin * length(cluster_1_spike_ts) * length(cluster_2_spike_ts) / T);
    r_01 = max([r_1,r_2]);

    q_00 = max([mean(K(i_range_1),"all"),mean(K(i_range_2),"all"),mean(K(i_range_3),"all")]);

    a = K(n_bins);
    K(n_bins) = 0;

    r_i = zeros(10,1);
    q_i = zeros(10,1);

    for i=1:length(q_i)
        i_range = n_bins-i:n_bins+i;
        r_i_0 = sum(K(i_range)) / (2 * i * t_bin * length(cluster_1_spike_ts) * length(cluster_2_spike_ts) / T);
        r_i(i) = r_i_0;

        n = sum(K(i_range),"all") /2;
        lam = q_00 * i;
        p = normcdf(n, lam, sqrt(2*lam + 1e-10));
        q_i(i) = p;
    end

    K(n_bins) = a;
    R12 = min(r_i) / (1e-10 + max([r_00,r_01]));
    Q12 = min(q_i);

    is_refractory(w)   = R12<acg_threshold  && (Q12<.2);%  or Q00<.25)
    is_cross_refractory(w) = R12<ccg_threshold && (Q12<.05);% or Q00<.25)
    %return is_refractory, cross_refractory, R12
    disp("Finished "+string(w)+"/"+string(size(blind_pass_table,1)));
end
blind_pass_table.is_refractory = is_refractory;
% blind_pass_table.is_cross_refractory = is_cross_refractory;

end