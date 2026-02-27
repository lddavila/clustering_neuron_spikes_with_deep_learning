function [] = test_ideal_width_for_sliding_window(blind_pass_table,config,make_plots)


%we'll use this function to attempt to identify an optimal meta-parameter
%window_width:
    %the number of neural network certainties that should be taken into
    %account when trying to determine which cluster is more likely to have
    %a higher accuracy
%there are 91 neural networks each trained to identify whether the current
%cluster is above/below threshold 1 ... 91
%Every single neural network is highly accuracte 88%+
%the hope is that by using the right of amount of neural network outcomes
%together then we can determine which cluster will have higher accuracy
%with a high degree of certainty
%this script serves to test different window widths for an ideal width

%create a directory to save the trained models
dir_to_save_results = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"Certainty Window Results"));

%set rng for reproducability
rng(0)
%get the raw data required for the neural network
list_of_features_to_add = ["grades 3"];
grades_array = [cell2mat(assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config))];

%get a table which displays all the nets that we 
table_of_nets = struct2table(dir(fullfile(config.dir_of_prob_dist_nets,"*.mat")));
net_names = string(table_of_nets.name);
split_net_names = split(net_names,"_");
[~,where_below_ends ]= find(split_net_names=="below");
net_nums = arrayfun(@(i) split_net_names(i, where_below_ends(i)+1), ...
    (1:size(split_net_names,1))');

%sort the nets by their threshold so that we have an ordered list of
%thresholds
table_of_nets.threshold = str2double(net_nums);
table_of_nets = sortrows(table_of_nets,"threshold","ascend");

%get the all the certainties for the all the grades
[~,unscaled_certainties ]= get_certainties_of_all_previous_nets(string(table_of_nets.name),config.dir_of_prob_dist_nets,grades_array);

%use the first 5 nets 
%those first 5 are trained to identify above/below thresholds [1, 2, 3, 4, 5]
%while none of the nets are 100% accurate they all have 88%+ accuracy
%we will take the consensus of their outputs as a way to filter out
%clusters that have less than 5% accuracy
first_five_certainties = unscaled_certainties(:,1:5);

%unscaled_certainties is a nx91 array where each value ranges between [-1,1]
    %n: number of rows in blind_pass_table
    %91: the number of thresholds that we have a neural network to identify
    %above/below 
        %network 1 is for threshold 1
        %network 2 is for threshold 2
        %...
        %network 91 is for threshold 91
    %Certainty Close to 1 : indicates the network i is highly certain that row n has a higher
    % accuracy than threshold i
    %Certainty Close to -1: indicates the network i is highly certain that row n has a lower
    % accuracy than threshold i
    %Certainty Close to 0: indicates the network is not certain one way or
    %the other

%if the majority of the first 5 networks all determine with a high degree of certainty
%that the example is above the first 5 thresholds then we can likely mark
%it as MUA and continue
elimination_condition =~(sum(first_five_certainties>=.9,2)>3);
blind_pass_table(elimination_condition, :) = [];
unscaled_certainties(elimination_condition,:) = [];
disp("Determined that "+string(sum(elimination_condition,"all"))+" were MUA and eliminated them from process")

%get all possible ways to compare any combinations of 2 clusters
%get all possible comparisons
blind_pass_idxs = 1:size(blind_pass_table,1);
all_possible_combinations = nchoosek(blind_pass_idxs,2);

%get the difference in accuracy between all the examples
abs_acc_diff = abs(blind_pass_table{all_possible_combinations(:,1)  ,"accuracy"} - blind_pass_table{all_possible_combinations(:,2),"accuracy"});

%assign some difficulty bins
difficulty_bins = [0,5,10,15,20,Inf];
difficulty_bin_id = get_difficulty_buckets_array(abs_acc_diff,difficulty_bins);

%get only the first n samples of the first difficuly bin (which is hardest)
n = 1000;
idx_of_first_n_samples = find(difficulty_bin_id==1,n);
non_example_one = find(difficulty_bin_id~=1);
%select the first 20 samples of the difficulty 1 class and combine them
%with the remaining comparisons samples
difficulty_bin_data = [all_possible_combinations([idx_of_first_n_samples;non_example_one],:),difficulty_bin_id([idx_of_first_n_samples;non_example_one])];

%remove any rows with NaNs;
difficulty_bin_data(any(isnan(difficulty_bin_data),2),:) = [];
%now equally sample the comparisons
%due to our previous data selection we should have at most 20 samples
%for each dificulty class
equalized_difficulty_rows = equalize_classes(difficulty_bin_data);

%remove the difficulty class from the data
equalized_difficulty_rows(:,end) = [];
%separate the is_left_better variable from the certainty data
left_cluster_certainties= unscaled_certainties(equalized_difficulty_rows{:,1},:);
right_cluster_certainties = unscaled_certainties(equalized_difficulty_rows{:,2},:);

true_left_accuracy = blind_pass_table{equalized_difficulty_rows{:,1}  ,"accuracy"};
true_right_accuracy =  blind_pass_table{equalized_difficulty_rows{:,2},"accuracy"}; 

is_left_better = true_left_accuracy > true_right_accuracy;
 
%set possible window widths
possible_widths = 3:1:20;

%now run through all the possible window widths and see which produces the highest
%accuracy
for i=1:length(possible_widths)
    current_width = possible_widths(i);
    left_cluster_window_averages = {};
    right_cluster_window_averages = {};
    for j=1:size(left_cluster_certainties,2)
        %we want our window to be rougly even if possible so we define the
        %beginning and end of our window to be centered at a certain
        %threshold j and take into account certainties on both sides
        window_beginning = max([1,j - round(current_width/2)]);
        window_end = min(j+round(current_width/2),size(left_cluster_certainties,2));

        %get the average certainty for the left cluster
        left_cluster_window_averages{end+1} = mean(left_cluster_certainties(:,window_beginning:window_end),2);
        right_cluster_window_averages{end+1} = mean(right_cluster_certainties(:,window_beginning:window_end),2);


    end

    flattened_left_window = cell2mat(left_cluster_window_averages);
    flattened_right_window = cell2mat(right_cluster_window_averages);

    %we'll derive some features that can we expect to be useful in
    %developing a model which can automatically determine which neural
    %network has a higher accuracy

    %row wise difference between the left/right clusters certainty
    cL = diff(flattened_left_window,1,2);
    cR = diff(flattened_right_window,1,2);


    %the derivative of the certainty curves for each cluster
    dL = diff(cL,1,2);
    dR = diff(cR,1,2);

    %the min derivative value for the left/right clusters and the index of
    %where that falls
    %jL = where the certainty curve drops the fastest for the left cluster
    [minDL, jL] = min(dL,[],2);
    %jR = where the certainty curve drops the fastest for the right cluster
    [minDR, jR] = min(dR,[],2);

    %negative value indicates that the right cluster has higher accuracy
    %positive value indicates the left cluster has higher accuracy
    delta_j = jL - jR;

    %sL and sR are measurements of how steep the cluster's certainty drop is
    %sharp drops means the certainty switched quickly from positive to
    %negative
    %shallow drops means that the transition was uncertain 
    %a larger s indicates the estimate is more trustworthy
    sL = -minDL; 
    sR = -minDR;
    %the difference between the sharpness of certainty drop
    delta_s = log((sL + eps) ./ (sR + eps));


    %the transition width difference
    alpha = 0.3; % a meta parameter to tune
    TL = dL < alpha.*minDL;
    TR = dR < alpha.*minDR;


    %small widths mean the drop is concentrated, the estimate is precise,
    %and all the nets agree tightly
    wL = sum(TL,2); 
    wR = sum(TR,2);
    %positive delta_w indicates the left cluster is more certain about its
    %decision that the right cluster
    delta_w = wR - wL;


    %split into training/testing data
    X = [delta_j, delta_s, delta_w];
    y = is_left_better(:);

    cv = cvpartition(length(y),'Holdout',0.3);
    tr = training(cv);
    te = test(cv);

    B = glmfit(X(tr,:), y(tr), 'binomial', 'link', 'logit');


    p = glmval(B, X(te,:), 'logit');
    pred = p > 0.5;
    acc = mean(pred == y(te));

    par_save(fullfile(dir_to_save_results,"binomial_model_accuracy_"+string(i)+"_"+sprintf("%.2f",acc)+".mat"),B);
    fprintf("%i/%i",i,length(possible_widths));

    if make_plots

        for j=1:length(left_cluster_window_averages)
            f = figure;
            tiledlayout(2,2);
            
            nexttile();
            bar(left_cluster_certainties(j,:),1);
            title("Left Cluster Certainties")
            xline(true_left_accuracy(j),"Label",sprintf("%.2f",true_left_accuracy(j)));
            xlabel("Accuracy")
            ylabel("Certainty")

            nexttile();
            bar(right_cluster_certainties(j,:),1);
            title("Right Cluster Certainties");
            xline(true_right_accuracy(j),"Label",sprintf("%.2f",true_right_accuracy(j)));

            xlabel("Accuracy")
            ylabel("Certainty")

            nexttile();
            bar(flattened_left_window(j,:),1);
            hold on;
            xline(true_left_accuracy(j),"Label",sprintf("%.2f",true_left_accuracy(j)));
            % plot(d_right(j,:),"LineWidth",3);
            title("Left Cluster Certainty Window Average");

            nexttile()
            bar(flattened_right_window(j,:),1);
            hold on;
            xline(true_right_accuracy(j),"Label",sprintf("%.2f",true_right_accuracy(j)));
            title("Right Cluster Window Averages")
            % plot(d_left(j,:),"LineWidth",3)
            close(f);
        end
    end

end
end