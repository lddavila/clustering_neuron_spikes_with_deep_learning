function [] = tinker_around_phase(blind_pass_table,config,testing,varargin)
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
timestamps = importdata(config.TIMESTAMP_FP);

if testing
    ground_truth = importdata(config.GT_FP);
end
if isempty(varargin)
    grouped_clusters = simple_grouping_parallel_ensemble(blind_pass_table,config,false);

else
    grouped_clusters = varargin{1};
end

%with the groups assembled we can then try to find alternate dimensions
%within each group to try and get the ideal configuration per neuron

for i=1:length(grouped_clusters)
    current_group = grouped_clusters{i};
    if testing
        current_group.fp_to_aligned = strrep(current_group.fp_to_aligned,"\",filesep);
        current_group.fp_to_aligned = strrep(current_group.fp_to_aligned,"F:",config.parent_save_dir);
        new_sorted_sw_name = strrep(current_group{1,"fp_to_sorted_spike_windows_after_purges"},"F:",config.parent_save_dir);
        pattern = 'initial_pass_results min multiplier 1';

        % Translate the wildcard pattern to a regex and replace with 'slow'
        new_sorted_sw_name = strrep(new_sorted_sw_name,pattern, "dictionaries multiplier 6 num_dps 60");
        new_sorted_sw_name = strrep(new_sorted_sw_name, "t1 sorted_spike_windows_after_purges.mat","");
        current_group.fp_to_sorted_spike_windows_after_purges = strcat(new_sorted_sw_name,current_group.Tetrode+" sorted_spike_windows.mat");
    else
    end
    unique_list_of_tetrodes = unique(current_group.Tetrode);
    unique_tetrode_nums = str2double(strrep(unique_list_of_tetrodes,"t",""));
    tetrode_channels = config.ART_TETR_ARRAY(unique_tetrode_nums,:);

    for j=1:height(current_group)
        curr_clust = current_group(j,:); %select a cluster to start with
        curr_clust.channels = tetrode_channels(unique_list_of_tetrodes==curr_clust.Tetrode,:);
        curr_aligned = load(curr_clust{1,"fp_to_aligned"});%import the aligned file for the current clust
        curr_aligned = curr_aligned.data_to_save.aligned; %get data instead of the wrapper
        curr_peaks = get_peaks(curr_aligned,true); %get the peaks (the features that will be clustered
        curr_clust_peaks = curr_peaks(:,curr_clust{1,"cluster_idx"}{1});
        curr_ts = curr_clust{1,"timestamps"}{1};
        [~,curr_pk_loc]= ismembertol(curr_ts,timestamps,config.TIME_DELTA,'DataScale',1); %get the location of the peaks for the current cluster
        curr_pk_loc(~curr_pk_loc) = []; %remove anything without a match should be redundant
        curr_sw = load(curr_clust{1,"fp_to_sorted_spike_windows_after_purges"});
        curr_sw = curr_sw.data_to_save.sorted_spike_windows_for_current_tetrode_dictionary(unique_list_of_tetrodes(unique_list_of_tetrodes==curr_clust.Tetrode));
        %the 4th column of current spike windows tells us the spike
        %location in ts
        %we the 3th column of current spike windows tells us which
        %channel the spike came from
        %we can use this information to get the spike windows for only
        %the compare cluster
        curr_clust_sw = curr_sw(ismembertol(curr_pk_loc,curr_sw(:,4),6,"DataScale",1),:); %6 is equivalent to the time delta which is 0.0002 seconds AKA .2 milliseconds

        curr_clust_ts = curr_clust{i,"timestamps"}{1};
        %TO DO: ENSURE THE PIPELINE outputs the sorted spike windows
        %appropriately as to not have to do all this extra finding with
        %tolerances we are currently doing here as it could create a
        %serious
        %bottleneck
        % curr_clust_sw = unique(curr_clust_sw,"rows","stable");
        if testing %see how accuracy is affected just by dropping dimensions 1 at a time
            gt_unit= ground_truth{curr_clust{1,"Max_Overlap_Unit"}};
            gt_ts = timestamps(gt_unit);
            all_possible_dimensions_to_drop = curr_clust.channels;
            accuracy_after_dropping = zeros(1,length(all_possible_dimensions_to_drop));

            all_perms = nchoosek(1:length(accuracy_after_dropping),2);
            for perms_counter =1: size(all_perms,1)
                figure;
                tiledlayout('flow');
                nexttile();
                dim_1 = all_perms(perms_counter,1);
                dim_2 = all_perms(perms_counter,2);
                x_data = curr_clust_peaks(dim_1,:);
                y_data = curr_clust_peaks(dim_2,:);
                histogram2(x_data,y_data,100)
                hold on;
                title("Without any Dropping")
                xlabel("channel "+string(all_possible_dimensions_to_drop(dim_1)));
                ylabel("channel "+string(all_possible_dimensions_to_drop(dim_2)));
                dropping_colors = distinguishable_colors(length(all_possible_dimensions_to_drop));
                for dim_counter=1:length(all_possible_dimensions_to_drop)
                    figure;
                    histogram2(x_data,y_data,100)
                    hold on;
                    edited_ts = curr_clust_ts(~ismember(curr_clust_sw(:,3),all_possible_dimensions_to_drop(dim_counter)));
                    edited_peaks = curr_clust_peaks(:,~ismember(curr_clust_sw(:,3),all_possible_dimensions_to_drop(dim_counter)));
                    x_data_edited = edited_peaks(dim_1,:);
                    y_data_edited = edited_peaks(dim_2,:);
                    accuracy_after_dropping(dim_counter) =  calculate_accuracy(gt_ts,{edited_ts},config) * 100;
                    histogram2(x_data_edited,y_data_edited,100,'FaceColor','k');
                    title("Dropping Channel "+string(all_possible_dimensions_to_drop(dim_counter))+" accuracy:"+string(accuracy_after_dropping(dim_counter)))
                    xlabel("channel "+string(all_possible_dimensions_to_drop(dim_1)));
                    ylabel("channel "+string(all_possible_dimensions_to_drop(dim_2)));
                end
                close all;


            end


            % title_string = [sprintf("accuracy %.2f after dropping for Z Score: %i , Tetrode: %s, Cluster: %i",curr_clust{1,"accuracy"},curr_clust{1,"Z Score"},curr_clust{1,"Tetrode"},curr_clust{1,"Cluster"})];
            % title_string = [title_string,strjoin(string(accuracy_after_dropping)," ")];
            % sgtitle(title_string);
            fprintf("accuracy %.2f after dropping for Multiplier: %i , Tetrode: %s, Cluster: %i\n",curr_clust{1,"accuracy"},curr_clust{1,"Z Score"}+5,curr_clust{1,"Tetrode"},curr_clust{1,"Cluster"})
            disp(accuracy_after_dropping)
            % continue;
        end

        for k=j+1:height(current_group) %cycle through all clusters you can compare to
            comp_clust = current_group(k,:); %get a cluster to compare to
            if curr_clust.Tetrode == comp_clust.Tetrode
                continue;%skip if if they are the same tetrode cause there's no way to drop/not drop dimensions
            end
            comp_clust.channels = tetrode_channels(unique_list_of_tetrodes==comp_clust.Tetrode,:);
            comp_aligned = load(comp_clust{1,"fp_to_aligned"});%import the aligned file for the compare clust
            comp_aligned = comp_aligned.data_to_save.aligned; %get data instead of the wrapper
            comp_peaks = get_peaks(comp_aligned,true); %get the peaks (the features that will be clustered
            comp_clust_peaks = comp_peaks(:,comp_clust{1,"cluster_idx"}{1});
            comp_ts = comp_clust{1,"timestamps"}{1};
            [~,comp_pk_loc]= ismembertol(comp_ts,timestamps,config.TIME_DELTA,'DataScale',1); %get the location of the peaks for the compare cluster
            comp_pk_loc(~comp_pk_loc) = []; %if any peaks don't have a timestamp then remove them, this should be redundant barring some glitch

            comp_sw = load(comp_clust{1,"fp_to_sorted_spike_windows_after_purges"});
            comp_sw = comp_sw.data_to_save.sorted_spike_windows_for_current_tetrode_dictionary(unique_list_of_tetrodes(unique_list_of_tetrodes==comp_clust.Tetrode));

            %the 4th column of compare spike windows tells us the spike
            %location in ts
            %we the 3rd column of compare spike windows tells us which
            %channel the spike came from
            %we can use this information to get the spike windows for only
            %the compare cluster

            comp_clust_sw = comp_sw(ismembertol(comp_sw(:,4),comp_pk_loc,6,"DataScale",1),:); %6 is equivalent to the time delta which is 0.0002 seconds AKA .2 milliseconds


            %currently there is no mechanism for choosing which new
            %dimensions should be added so we're just gonna see what
            %happens if you randomly add dimensions from other clusters
            dimensions_to_add = comp_clust.channels;
            if testing %see how accuracy is affected just by dropping dimensions 1 at a time
                for add_counter=1:length(dimensions_to_add)
                    gt_unit= ground_truth{curr_clust{1,"Max_Overlap_Unit"}};
                    gt_ts = timestamps(gt_unit);
                    all_possible_dimensions_to_drop = curr_clust.channels;
                    new_dims = [all_possible_dimensions_to_drop,dimensions_to_add(add_counter)];
                    accuracy_after_adding = zeros(1,length(new_dims));
                    %get the spikes which appear on the channel that we
                    %wish to add
                    spikes_to_add = comp_clust_sw(comp_clust_sw(:,3)==dimensions_to_add(add_counter),:);
                    all_perms = nchoosek(1:length(accuracy_after_adding),2);
                    new_combined_sw = [curr_sw;spikes_to_add];
                    new_cluster_sw = reassemble_spikes(new_combined_sw,config);
                    new_spikes = reassemble_spikes(new_cluster_sw,config,new_dims,);
                    for perms_counter =1: size(all_perms,1)
                        figure;
                        
                        dim_1 = all_perms(perms_counter,1);
                        dim_2 = all_perms(perms_counter,2);
                        x_data = curr_clust_peaks(dim_1,:);
                        y_data = curr_clust_peaks(dim_2,:);
                        histogram2(x_data,y_data,100)
                        hold on;
                        title("Without any Adding")
                        xlabel("channel "+string(all_possible_dimensions_to_drop(dim_1)));
                        ylabel("channel "+string(all_possible_dimensions_to_drop(dim_2)));

                        for dim_counter=1:length(all_possible_dimensions_to_drop)
                            figure;
                            histogram2(x_data,y_data,100)
                            hold on;
                            edited_ts = curr_clust_ts(~ismember(curr_clust_sw(:,3),all_possible_dimensions_to_drop(dim_counter)));
                            edited_peaks = curr_clust_peaks(:,~ismember(curr_clust_sw(:,3),all_possible_dimensions_to_drop(dim_counter)));
                            x_data_edited = edited_peaks(dim_1,:);
                            y_data_edited = edited_peaks(dim_2,:);
                            accuracy_after_dropping(dim_counter) =  calculate_accuracy(gt_ts,{edited_ts},config) * 100;
                            histogram2(x_data_edited,y_data_edited,100,'FaceColor','k');
                            title("Dropping Channel "+string(all_possible_dimensions_to_drop(dim_counter))+" accuracy:"+string(accuracy_after_dropping(dim_counter)))
                            xlabel("channel "+string(all_possible_dimensions_to_drop(dim_1)));
                            ylabel("channel "+string(all_possible_dimensions_to_drop(dim_2)));
                        end
                        close all;


                    end


                    % title_string = [sprintf("accuracy %.2f after dropping for Z Score: %i , Tetrode: %s, Cluster: %i",curr_clust{1,"accuracy"},curr_clust{1,"Z Score"},curr_clust{1,"Tetrode"},curr_clust{1,"Cluster"})];
                    % title_string = [title_string,strjoin(string(accuracy_after_dropping)," ")];
                    % sgtitle(title_string);
                    fprintf("accuracy %.2f after dropping for Multiplier: %i , Tetrode: %s, Cluster: %i\n",curr_clust{1,"accuracy"},curr_clust{1,"Z Score"}+5,curr_clust{1,"Tetrode"},curr_clust{1,"Cluster"})
                    disp(accuracy_after_dropping)
                end
                % continue;
            end
        end
    end

end

end