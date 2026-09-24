function [] = train_a_hierarchacal_net_ver_3(options)
arguments
    options.blind_pass_table table = cell2table(cell(0,1));
    options.bounds = 0:5:100;
end
    function [train_data,val_data,test_data] = split_the_blind_pass_table(blind_pass_table)
        data_split = partition_bp_tables(blind_pass_table,false,"split_into_test_train_val",true);
        train_data = data_split{1};
        val_data = data_split{2};
        test_data = data_split{3};
    end

    

    function [folded_data] = structure_data_into_folds(blind_pass_table)
        folded_blind_pass = partition_bp_tables(blind_pass_table,false,"split_into_folds",true);
        folded_data = cell(length(folded_blind_pass),3);
        for q=1:size(folded_data,1)
            data_split = partition_bp_tables(folded_blind_pass{q},false,"split_into_test_train_val",true);
            current_train = data_split{1};
            current_val = data_split{2};
            current_test = data_split{3};
            folded_data{q,1} = current_train;
            folded_data{q,2} = current_val;
            folded_data{q,3} = current_test;


        end
    end
    function networks = get_multiple_nns(number_of_nets_required,number_of_grades,num_classes)
        networks = cell(number_of_nets_required,1);
        for p=1:number_of_nets_required
            networks{p} = dynamically_create_layers_for_nn(number_of_grades,5,5,num_classes);
        end
    end
    function [folded_data] = add_difficulty_class_and_true_class_to_folded_data(folded_data,current_split_point,balance,bounds)
        min_group_size = 100;
        for q=1:size(folded_data,1)
            current_train_data = folded_data{q,1};
            current_val_data = folded_data{q,2};
            current_test_data = folded_data{q,3};
            current_train_data.local_class = current_train_data{:,"accuracy"} >= current_split_point;
            current_val_data.local_class = current_val_data{:,"accuracy"} >= current_split_point;
            current_test_data.local_class = current_test_data{:,"accuracy"} >= current_split_point;
            if any(bounds < 0)
                current_train_data.difficulty_class = discretize(current_train_data{:,"accuracy"}-current_split_point,bounds);
                current_val_data.difficulty_class = discretize(current_val_data{:,"accuracy"}-current_split_point,bounds);
                current_test_data.difficulty_class = discretize(current_test_data{:,"accuracy"}-current_split_point,bounds);
            else
                current_train_data.difficulty_class = discretize(abs(current_train_data{:,"accuracy"}-current_split_point),bounds);
                current_val_data.difficulty_class = discretize(abs(current_val_data{:,"accuracy"}-current_split_point),bounds);
                current_test_data.difficulty_class = discretize(abs(current_test_data{:,"accuracy"}-current_split_point),bounds);
            end
            if balance
                training_subset = current_train_data;
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
                [G, ~] = findgroups(training_subset(:,["local_class","difficulty_class"]));

                row_indices = (1:height(training_subset))';
                group_counts = splitapply(@numel,row_indices,G);

                if isempty(group_counts)
                    error("No training groups contain at least %d observations.",min_group_size);
                end

                % Balance retained groups to the size of the smallest retained group
                samples_per_group = min(group_counts);

                sampled_rows = splitapply(@(rows) {datasample(rows,samples_per_group,"Replace",false)},row_indices,G);

                sampled_rows = vertcat(sampled_rows{:});
                balanced_training = training_subset(sampled_rows,:);

                folded_data{q,1} = balanced_training;
            else
                folded_data{q,1} = current_train_data;


            end
            folded_data{q,2} = current_val_data;
            folded_data{q,3} = current_test_data;

        end

    end
    function [net_to_preserve,routed_above,routed_below,val_data,test_data,final_mu,final_sigma] = train_network_in_fold(data,tree_nodes,results_dir,bounds,current_node,current_split_point)

        %first get the initial training/test/split
        if current_split_point==50
            [train_data,val_data,test_data] = split_the_blind_pass_table(data);
        else
            train_data = data;
            val_data = [];
            test_data = [];
        end
        %now split the training data into folds
        rng(0);
        
        [folded_data]= structure_data_into_folds(train_data);

        %now we get a 10 networks 1 of which will be the permanent net and
        %the other 9 will be the permanent ones
        networks = get_multiple_nns(length(folded_data),size(train_data.grades,2),2);
        trained_networks = cell(1,length(networks));
        % for b =1:length(tree_nodes)
        % for c=1:length(current_node)
        net_save_string = "Layer_"+string(current_node)+"split_point_"+string(current_split_point)+"_accuracy_";
        preserved_folded_data = folded_data;
        
        folded_data = add_difficulty_class_and_true_class_to_folded_data(folded_data,current_split_point,true,bounds);

        routed_below = [];
        routed_above = [];
        all_folds = 1:1:length(networks);
        temp_nets_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(results_dir,"temp_nets_for_split_"+string(current_split_point)));
        num_iterations = length(networks);
        already_done_nets = struct2table(dir(fullfile(temp_nets_dir,"*.mat")));
        already_done_nets.folder = string(already_done_nets.folder);
        already_done_nets.name = string(already_done_nets.name);
        parfor a=1:length(networks)
            temp_net_name = "split_point_"+string(current_split_point)+"a_is_"+string(a)+"_accuracy_";
            if ~any(contains(already_done_nets.name,"split_point_"+string(current_split_point)+"a_is_"+string(a)+"_accuracy"))
                data_to_use = setdiff(all_folds,a);
                current_network = networks{a};
                current_train= vertcat(folded_data{data_to_use,1});
                current_valid = vertcat(folded_data{data_to_use,2});
                current_test = vertcat(folded_data{data_to_use,3});
                
                [current_train,current_test,current_valid,~,mu,sigma] = normalize_the_data(current_train,"current_test",current_test,"current_val",current_valid);

                % local_preserved_folded_data = ;
                trained_networks{a} = train_a_net([current_train.grades,current_train.local_class],[current_valid.grades,current_valid.local_class],current_network,64);
                scores = predict(trained_networks{a},current_test.grades);

                [~,YPred] = max(scores,[],2);
                YPred = YPred-1;
                % YPred = double(~(scores(:,2) < .90));

                YTest = current_test{:,"local_class"};
                accuracy = sum(YPred== YTest)/numel(YTest);
                disp("accuracy on test for split point " +string(current_split_point))
                disp(accuracy)
                net_struct = struct();
                net_struct.network = trained_networks{a};
                net_struct.sigma = sigma;
                net_struct.mu = mu;
                net_struct.accuracy = accuracy;
                temp_net_name = temp_net_name+sprintf("%.2f",accuracy)+".mat";
                par_save(fullfile(temp_nets_dir,temp_net_name),net_struct)
            else
                net_struct = importdata(fullfile(already_done_nets{a,"folder"},already_done_nets{a,"name"}));
                trained_networks{a} = net_struct.network;
                mu = net_struct.mu;
                sigma = net_struct.sigma;
                accuracy = net_struct.accuracy;
                disp("accuracy on test for split point " +string(current_split_point))
                disp(accuracy)
            end
            %now route the folded data through networks that have
            %never seen them before
            [routed_train,routed_test,routed_val] = normalize_the_data(preserved_folded_data{a,1},"current_test",preserved_folded_data{a,2},"current_val",preserved_folded_data{a,3},"mu",mu,"sigma",sigma);
            data_to_be_routed = [routed_train;routed_test;routed_val];
            route_predictions = predict(trained_networks{a},data_to_be_routed.grades);
            [~,route_predictions] = max(route_predictions,[],2);
            route_predictions = route_predictions -1;
            unedited_routed = [preserved_folded_data{a,1};preserved_folded_data{a,2};preserved_folded_data{a,3}];

            routed_below = [routed_below;unedited_routed(logical(~route_predictions),:)];
            routed_above = [routed_above;unedited_routed(logical(route_predictions),:)];

            disp("Finished "+string(a)+ "/ "+string(num_iterations));

        end

        % OOF loop creates routed_above and routed_below

        % Now construct and train a separate final permanent network
        final_train = vertcat(folded_data{:,1});
        final_valid = vertcat(folded_data{:,2});
        final_test  = vertcat(folded_data{:,3});

        
        [final_train,final_valid,final_test,~,final_mu,final_sigma] = ...
            normalize_the_data(final_train,"current_val",final_valid,"current_test",final_test);

        net_to_preserve = dynamically_create_layers_for_nn( ...
            size(final_train.grades,2),5,5,2);

        already_done_nets = struct2table(dir(fullfile(results_dir,"*.mat")));
        already_done_nets.folder = string(already_done_nets.folder);
        already_done_nets.name = string(already_done_nets.name);
        if ~any(contains(already_done_nets.name,net_save_string))
            net_to_preserve = train_a_net( ...
                [final_train.grades,final_train.local_class], ...
                [final_valid.grades,final_valid.local_class], ...
                net_to_preserve,64);
            save_struct = struct();
            save_struct.net = net_to_preserve;
            save_struct.mu = final_mu;
            save_struct.sigma = final_sigma;
        else
            idx = find(contains(already_done_nets.name,net_save_string),1);
            save_struct = importdata(fullfile(already_done_nets{idx,"folder"},already_done_nets{idx,"name"}));
            net_to_preserve = save_struct.net;
            final_mu = save_struct.mu;
            final_sigma = save_struct.sigma;
        end



        route_predictions = predict(net_to_preserve,final_test.grades);

        [~,route_predictions] = max(route_predictions,[],2);
        route_predictions = route_predictions -1;

        YTest = final_test{:,"local_class"};
        accuracy = sum(route_predictions== YTest)/numel(YTest);
        disp("accuracy for permanent net " +string(current_split_point))
        disp(accuracy)
        net_save_string = net_save_string + sprintf("%.2f",accuracy);

        par_save(fullfile(results_dir,net_save_string+".mat"),save_struct);

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
if isempty(options.blind_pass_table)
    blind_pass_table = importdata(config.FP_TO_EVEN_NUMBERED_RECORDINGS);
else
    blind_pass_table = options.blind_pass_table;
end

%create a directory to save nets and results to
results_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"hierarchal_nets_fixed_nan_issue_ver_4"));
%set the seed
rng(0)

%first shuffle the blind pass table so the 4/3/2 channel examples are mixed
%in with each other
blind_pass_table = blind_pass_table(randperm(height(blind_pass_table),height(blind_pass_table)),:);


%assemble the training data into simple to handle forms
list_of_features_to_add = ["grades 3"];
all_grades_formatted = [cell2mat(assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config))];
% Returns a logical column vector (1 for rows with complex numbers, 0 otherwise)
row_mask = any(imag(all_grades_formatted) ~= 0, 2);
% all_grades_formatted(isnan(all_grades_formatted)) = 0;
remove_condition = [row_mask];

data_table = [blind_pass_table(~row_mask,["Z Score","Tetrode","Cluster","Max_Overlap_Unit","accuracy"]),table(all_grades_formatted(~row_mask,:),'VariableNames',["grades"])];
splits = {[50], [75, 25]};


cell_array_of_nets = cell(3,1);
cell_array_of_mus = cell(3,1);
cell_array_of_sigmas = cell(3,1);
position = 1;
for level_tracker = 1:length(splits)
    current_level = splits{level_tracker};
    for split_tracker=1:length(current_level)
        if level_tracker ==1
            [cell_array_of_nets{position},routed_above,routed_below,validation,testing,cell_array_of_mus{position},cell_array_of_sigmas{position}] = train_network_in_fold(data_table,splits,results_dir,options.bounds,level_tracker,current_level(split_tracker));
        elseif level_tracker ~=1 && split_tracker==1
            [cell_array_of_nets{position},~,~,~,~,cell_array_of_mus{position},cell_array_of_sigmas{position}] = train_network_in_fold(routed_above,splits,results_dir,options.bounds,level_tracker,current_level(split_tracker));
        elseif level_tracker ~=1 && split_tracker==2
            [cell_array_of_nets{position},~,~,~,~,cell_array_of_mus{position},cell_array_of_sigmas{position}] = train_network_in_fold(routed_below,splits,results_dir,options.bounds,level_tracker,current_level(split_tracker));
        end
        position = position+1;
    end
end
clc;
%now use the validation to test the entire hierarchy
testing_data = [validation;testing];
testing_data_for_prediction = normalize_the_data(testing_data,"mu",cell_array_of_mus{1},"sigma",cell_array_of_sigmas{1});

official_true_classes = zeros(height(testing_data),1);
official_true_classes(testing_data.accuracy>= 0 & testing_data.accuracy <25) = 1;
official_true_classes(testing_data.accuracy>= 25 & testing_data.accuracy <50) = 2;
official_true_classes(testing_data.accuracy>= 50 & testing_data.accuracy <75) = 3;
official_true_classes(testing_data.accuracy>= 75 & testing_data.accuracy <100) = 4;
testing_data_for_prediction.true_class = official_true_classes;
testing_data.true_class = official_true_classes;


predicted_routes = predict(cell_array_of_nets{1},testing_data_for_prediction.grades);
[~,predicted_class] = max(predicted_routes,[],2);
predicted_class = predicted_class -1;

true_direction_for_50 = testing_data.accuracy >= 50;
for_25_node = testing_data(~logical(predicted_class),:);
for_75_node = testing_data(logical(predicted_class),:);

accuracy_at_first_split = sum(predicted_class==true_direction_for_50) /numel(predicted_class);
disp("At first layer our accuracy is");
disp(accuracy_at_first_split);

for_25_node_for_prediction = normalize_the_data(for_25_node,"mu",cell_array_of_mus{3},"sigma",cell_array_of_sigmas{3});


predictions_at_25 = predict(cell_array_of_nets{3},for_25_node_for_prediction.grades);
true_direction_for_25 = for_25_node_for_prediction.accuracy >= 25;
[~,above_or_below_25]= max(predictions_at_25,[],2);
above_or_below_25 = above_or_below_25 -1;
accuracy_at_25 = sum(true_direction_for_25==above_or_below_25)/numel(true_direction_for_25);
disp("accuracy at the 25 split")
disp(accuracy_at_25)
predicted_final_class = zeros(height(for_25_node_for_prediction),1);
predicted_final_class(logical(above_or_below_25)) =2;
predicted_final_class(~logical(above_or_below_25)) =1;
for_25_node_for_prediction.predicted_final_class = predicted_final_class; 



for_75_node_for_prediction = normalize_the_data(for_75_node,"mu",cell_array_of_mus{2},"sigma",cell_array_of_sigmas{2});
predictions_at_75 = predict(cell_array_of_nets{2},for_75_node_for_prediction.grades);
true_direction_for_75 = for_75_node_for_prediction.accuracy >= 75;
[~,above_or_below_75 ]= max(predictions_at_75,[],2);
above_or_below_75 = above_or_below_75 -1;
accuracy_at_75 = sum(true_direction_for_75==above_or_below_75)/numel(true_direction_for_75);
disp("accuracy at the 75 split");
disp(accuracy_at_75);
predicted_final_class = zeros(height(for_75_node_for_prediction),1);
predicted_final_class(logical(above_or_below_75)) =4;
predicted_final_class(~logical(above_or_below_75)) =3;
for_75_node_for_prediction.predicted_final_class = predicted_final_class; 

rejoined_table = [for_25_node_for_prediction;for_75_node_for_prediction];

final_class_performance = sum(rejoined_table.true_class == rejoined_table.predicted_final_class)/height(rejoined_table);
disp("Final categorization accuracy");
disp(final_class_performance)



end