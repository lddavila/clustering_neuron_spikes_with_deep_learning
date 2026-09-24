function [] = train_a_hierarchacal_net_ver_2(options)
arguments
    options.blind_pass_table table = cell2table(cell(0,1));
    options.bounds = 0:5:100;
end
    function [trained_net,YPred] = do_training(current_split_point,results_dir,to_add,training_data,testing_data,validation_data,col_min,col_max,mu,sigma,balance_or_dont,bounds)
        % current_split_point = split_points(i);
        net_save_name = fullfile(results_dir,sprintf(to_add+"net_for_split_at_%.f",current_split_point)+".mat");
        graph_save_name = fullfile(results_dir,sprintf(to_add+"chart_for_split_at_%.f",current_split_point));

        if isfile(net_save_name) && isfile(graph_save_name+".mat")
            return
        end
        %now we'll add a difficulty class to our data
        %this class is not to be predicted, but to ensure that accuracy does
        %not mislead us because the proportion of trivial cases typically
        %outnumber the difficult casses
        training_data.difficulty_class = discretize(current_split_point - training_data.accuracy,bounds);
        testing_data.difficulty_class = discretize(current_split_point - testing_data.accuracy,bounds);
        validation_data.difficulty_class = discretize(current_split_point - validation_data.accuracy,bounds);

        %add a class specific to try and categorize the true accuracy as
        %above/below the split point
        training_data.local_class = training_data.accuracy >= current_split_point;
        validation_data.local_class = validation_data.accuracy >= current_split_point;
        testing_data.local_class = testing_data.accuracy >= current_split_point;

        min_group_size = 100;

        % Distance from the current threshold
        training_data.difficulty_class = discretize(current_split_point - training_data.accuracy,bounds);

        % Remove rows with undefined difficulty classes
        training_subset = training_data( ...
            ~isundefined(categorical(training_data.difficulty_class)), :);

        % Form joint local-class/difficulty-class groups
        [G, ~] = findgroups( ...
            training_subset(:,["local_class","difficulty_class"]));

        row_indices = (1:height(training_subset))';
        group_counts = splitapply(@numel,row_indices,G);

        % Identify groups large enough to retain
        large_enough_groups = group_counts >= min_group_size;

        % Map the group-level condition back to individual rows
        keep_rows = large_enough_groups(G);
        training_subset = training_subset(keep_rows,:);

        % Recompute groups after removing small ones
        [G, ~] = findgroups( ...
            training_subset(:,["local_class","difficulty_class"]));

        row_indices = (1:height(training_subset))';
        group_counts = splitapply(@numel,row_indices,G);

        if isempty(group_counts)
            error("No training groups contain at least %d observations.", ...
                min_group_size);
        end

        % Balance retained groups to the size of the smallest retained group
        samples_per_group = min(group_counts);

        sampled_rows = splitapply( ...
            @(rows) {datasample(rows,samples_per_group,"Replace",false)}, ...
            row_indices,G);

        sampled_rows = vertcat(sampled_rows{:});
        balanced_training = training_subset(sampled_rows,:);

        training_subset = validation_data;
        % repeat to balance validation data
        % Form joint local-class/difficulty-class groups
        [G, ~] = findgroups(training_subset(:,["local_class","difficulty_class"]));

        row_indices = (1:height(training_subset))';
        group_counts = splitapply(@numel,row_indices,G);

        % Identify groups large enough to retain
        large_enough_groups = group_counts >= min_group_size;

        % Map the group-level condition back to individual rows
        keep_rows = large_enough_groups(G);
        training_subset = training_subset(keep_rows,:);

        % Recompute groups after removing small ones
        [G, ~] = findgroups( ...
            training_subset(:,["local_class","difficulty_class"]));

        row_indices = (1:height(training_subset))';
        group_counts = splitapply(@numel,row_indices,G);

        if isempty(group_counts)
            error("No training groups contain at least %d observations.", ...
                min_group_size);
        end

        % Balance retained groups to the size of the smallest retained group
        samples_per_group = min(group_counts);

        sampled_rows = splitapply( ...
            @(rows) {datasample(rows,samples_per_group,"Replace",false)}, ...
            row_indices,G);

        sampled_rows = vertcat(sampled_rows{:});
        balanced_validation = training_subset(sampled_rows,:);


        %we don't do this to the same to testing/validation data because we
        %actually WANT to see how it performs on realistic data
        %the proportion split we implement in training is not guaranteed

        %now build a net based on our needs
        layers_of_net = dynamically_create_layers_for_nn(size(balanced_training.grades,2),5,5,length(unique(balanced_training.local_class)));

        % local_grades = balanced_training.grades ;
        % local_grades(any(isnan(local_grades),2),:) = [];
        % balanced_training.grades = local_grades;




        %now train that net and get results
        if balance_or_dont
            [trained_net] = train_a_net([balanced_training.grades,balanced_training.local_class],[balanced_validation.grades,balanced_validation.local_class],layers_of_net,32);
        else
            [trained_net] = train_a_net([balanced_training.grades,balanced_training.local_class],[validation_data.grades,validation_data.local_class],layers_of_net,32);
        end

        scores = predict(trained_net,testing_data.grades);

        [~,YPred] = max(scores,[],2);
        YPred = YPred-1;
        % YPred = double(~(scores(:,2) < .90));

        YTest = testing_data{:,"local_class"};
        accuracy = sum(YPred== YTest)/numel(YTest);
        disp("accuracy on test")
        disp(accuracy)

        %now get a breakdown of how the success/faliure cases break down


        
        x_labels = strcat(string(bounds(1:end-1)), " to ",string(bounds(2:end)));
        list =1:1:length(x_labels);
        all_data = zeros(length(x_labels),2);
        for j=1:length(list)
            c1 = YTest==YPred;
            c2 = testing_data{:,"difficulty_class"} == list(j);
            all_data(j,1) = sum(c1 & c2);
            all_data(j,2) = sum(~c1 & c2);
        end

        f = figure;


        total = sum(all_data, 2);
        failure_rate = all_data(:,2) ./ total;
        failure_rate(total == 0) = NaN;
        tiledlayout(2,1);


        nexttile();
        b = bar(x_labels,all_data);
        for p = 1:numel(b)
            text(b(p).XEndPoints, b(p).YEndPoints, string(b(p).YData), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom');
        end
        xlabel("Difficulty level (closest to 0 is harder) ");
        ylabel("Frequency");
        legend("Successes","Faliures")
        title("Raw Success and faliure counts")

        nexttile();
        bar(x_labels,100*failure_rate)
        ylabel("Failure rate (%)");
        xlabel("Absolute distance from "+string(current_split_point)+"% threshold");
        ylim([0 100]);
        title("Faliure Rate (lower is better) ")
        xtickangle(45);

        sgtitle("Classification failure rate by distance");
        net_struct = struct();
        net_struct.trained_net = trained_net;
        net_struct.col_min = col_min;
        net_struct.col_max = col_max;
        net_struct.mean = mu;
        net_struct.std = sigma;
        net_struct.accuracy = accuracy;
        % legend("")

        % title("Successes and Failures broken down by difficulty of task")
        net_struct.breakdown = all_data;
        par_save(net_save_name,net_struct);

        save_plots_in_all_formats(f,graph_save_name);
    end

%add path
home_dir = cd("..");
cd("..");
addpath(genpath(fullfile(pwd,"Neural_Networks/")));
addpath(genpath(fullfile(pwd,"Grading_scripts")));
addpath(genpath(fullfile(pwd,"clustering-master")));
addpath(genpath(fullfile(pwd,"Utility_Functions")));
cd(home_dir)
config = spikesort_config();
if size(options.blind_pass_table) == 0
    blind_pass_table = importdata(config.FP_TO_EVEN_NUMBERED_RECORDINGS);
else
    blind_pass_table = options.blind_pass_table;
end

%create a directory to save nets and results to
results_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"hierarchal_nets_fixed_nan_issue_ver_2"));
%set the seed
rng(0)

%first shuffle the blind pass table so the 4/3/2 channel examples are mixed
%in with each other
blind_pass_table = blind_pass_table(randperm(height(blind_pass_table),height(blind_pass_table)),:);


%assemble the training data into simple to handle forms
list_of_features_to_add = ["grades 3"];
all_grades_formatted = [cell2mat(assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config))];

data_table = [blind_pass_table(:,["Z Score","Tetrode","Cluster","Max_Overlap_Unit","accuracy"]),table(all_grades_formatted(:,:),'VariableNames',["grades"])];

split_data = partition_bp_tables(data_table,false);
training_data = split_data{1,1};
testing_data = split_data{1,2};
col_min = min(training_data.grades);
col_max = max(training_data.grades);


split_again = partition_bp_tables(training_data,false);
training_data = split_again{1,1};
validation_data = split_again{1,2};

mu = mean(training_data.grades, 1, "omitnan");
sigma = std(training_data.grades, 0, 1, "omitnan");

training_data.grades = (training_data.grades - mu)./ sigma;

testing_data.grades = (testing_data.grades-mu) ./ sigma;
validation_data.grades = (validation_data.grades - mu) ./ sigma;

training_data.grades(isnan(training_data.grades)) = 0;
testing_data.grades(isnan(testing_data.grades)) = 0;
validation_data.grades(isnan(validation_data.grades)) = 0;

%create accuracy classes which will serve as our ground truth
training_data.final_y_labels = discretize(training_data.accuracy,0:10:100);
testing_data.final_y_labels = discretize(testing_data.accuracy,0:10:100);
validation_data.final_y_labels = discretize(validation_data.accuracy,0:10:100);
% secondary_data_table.final_y_labels = discretize(secondary_data_table.accuracy,0:10:100);


%define where you want each tree to form
split_points = [70];

%the phenomena we have observed is that when you train a nerual network to
%identify above/below a specifc threshold (i.e. accuracy = 1, 10, 20, etc)
%it is highly accurate (80-99%) for cases where the cluster's true accuracy is far above/below the accuracy threshold
%(i.e. true accuracy is 10% and threshold accuracy = 40+ accuracy points
%away)
%this is true even controlling for the number of
%above/below instances during training and controlling for the difficulty
%of the case
%but as the true accuracy and threshold accuracy become closer the less
%reliable the neural network becomes

%we've tried with some accuracy to predict the true accuracy by using
%certainty of the neural network's predictions as a indicator as to where
%the true accuracy lies
%this resulted in the median distance of predicted accuracy to true
%accuracy was 8pts (we have no indication towards direction so this leads
%to a 16 point margin of error)

%in an effort to try and improve this we want to try and build some
%hierarchy into the ensemble to improve performance

%the general idea is that if you set the first split to a high-ish accuracy
% (70% accurate) then we avoid the "worst case", defined as confusing a
% very low accuracy cluster (<10% accuracy) with a high accuracy cluster
% (>80%)

% we know that regardless of the threshold the NNs ability to classify it
% become worse as the true accuracy approaches it
% so by splitting a high accuracy point the worst thing that happens is
% that accuracy 65% accuracy is confused to be 70%+ accurate
% or that a 75% accuracy is predicted to be <70% accurate

% the truly high accuracies (>80% accuracy) should still pass without problem
% and those who are borderline can continue down the network tree ensemble

balance_validation_or_dont = [1];
for k=1:length(balance_validation_or_dont)
    if balance_validation_or_dont(k)
        to_add = "balanced_";
    else
        to_add = "";
    end
    for i=1:length(split_points)
        %do_training(current_split_point,results_dir,to_add,training_data,testing_data,validation_data,col_min,col_max,mu,sigma,balance_or_dont)
        [trained_net,testing_predictions] = do_training(split_points(i),results_dir,to_add,training_data,testing_data,validation_data,col_min,col_max,mu,sigma,balance_validation_or_dont(k),options.bounds);
    end
end

%with the first net trained we have to construct a new training set
%untouched for the next split, so that we don't contaminate the layers
below_branch = testing_data(~testing_predictions,:);
above_branch = testing_data(testing_predictions,:);

split_points = [50,60,80];
for k=1:length(balance_validation_or_dont)
    if balance_validation_or_dont(k)
        to_add = "second_level_balanced_";
    else
        to_add = "second_level_";
    end

    for i=1:length(split_points)
        if split_points(i) < 70
            new_split = partition_bp_tables(below_branch,false);
        else
            new_split = partition_bp_tables(above_branch,false);
        end
        new_training = new_split{1,1};
        new_testing = new_split{1,2};

        split_again = partition_bp_tables(new_training,false);
        new_training = split_again{1,1};
        new_validation = split_again{1,2};
        [trained_net,testing_predictions]= do_training(split_points(i),results_dir,to_add,new_training,new_testing,new_validation,col_min,col_max,mu,sigma,balance_validation_or_dont(k),options.bounds);
    end
end
end