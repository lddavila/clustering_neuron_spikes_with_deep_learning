function [] = get_deep_breakdown_of_siamese_net_performance(net_struct,blind_pass_table,config)
%remove any examples for very low accuracy
blind_pass_table(blind_pass_table{:,"accuracy"}<1,:)=[];
% --- Features ---
list_of_features_to_add = ["grades 2","valley_1","valley_2"];

data_to_analyze = assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config);
data_to_analyze = cell2mat(data_to_analyze);

%get the siamese net
net = net_struct.net;

%get the normalization features
col_min = net_struct.col_min;
col_max = net_struct.col_max;

%normalize data_to_analyze
data_to_analyze = rescale(data_to_analyze,0,1,"InputMax",col_max,"InputMin",col_min);
disp("Finished normalizing data")
%set some buckets of difficulty
difficulty_buckets = [0,1,5,10,20,30,40,50,60];

%minimize the number of comparisons
number_of_comparisons = round(size(data_to_analyze,1)/5);
%take them from the end instead of the beginning because it was trainined
%on data towards beginning
all_comparisons = nchoosek(size(blind_pass_table,1)-number_of_comparisons:size(blind_pass_table,1),2);
disp("Finished getting comparisons")
%get the true class of the comparisons
true_class = blind_pass_table{all_comparisons(:,1),"accuracy"} >  blind_pass_table{all_comparisons(:,2),"accuracy"};
disp("Finished getting true class")
%get the magnitude of accuracy differences for the comparisons
mag_of_diff =abs(blind_pass_table{all_comparisons(:,1),"accuracy"} -  blind_pass_table{all_comparisons(:,2),"accuracy"});
disp("Finished getting mag of accuracy differences")
comparison_difficulty_bucket = get_difficulty_buckets_array(mag_of_diff,difficulty_buckets);
disp("Finished getting difficulty buckets")
% tabulate(comparison_difficulty_bucket);



%we'll also want to create buckets for accuracy since there are a lot of
%permutations that can be created
accuracy_buckets = [1,10,20,30,40,50,60,70,80,90];
number_of_buckets = 11;
%now for each of the comparions and difficulty buckets see the breakdown of
%accuracy
accuracy_per_bucket = cell(1,length(difficulty_buckets)-1);
for i=1:length(accuracy_per_bucket)
    % current_matrix = zero(length(accuracy_buckets)-1,length(accuracy_buckets)-1);
    %select comparisons which are only in the current difficulty bucket
    current_bucket_subset = all_comparisons(comparison_difficulty_bucket==i,:);
    true_class_subset = true_class(comparison_difficulty_bucket==i);
    X1dl = dlarray(single(data_to_analyze(current_bucket_subset(:,1),:).'),"CB");
    X2dl = dlarray(single(data_to_analyze(current_bucket_subset(:,2),:).'),"CB");
    Predictions = predictTwin(net,X1dl,X2dl);
    Predictions = gather(extractdata(Predictions));
    Predictions = round(Predictions);            % 0/1
    [row,col] = get_accuracy_buckets(blind_pass_table{current_bucket_subset(:,1),"accuracy"},blind_pass_table{current_bucket_subset(:,2),"accuracy"},accuracy_buckets);

    %first thing we'll want to do is to establish a count matrix for each
    %bucket
    count_matrix = zeros(number_of_buckets,number_of_buckets);

    %then for every row/col you increase the count
    for j=1:length(row)
        % fprintf("row:%i col:%i i:%i\n",row(j),col(j),i)
        count_matrix(row(j),col(j)) =  count_matrix(row(j),col(j))+1;
    end

    %now we'll create an an accuracy matrix to sum the accuracies
    accuracy_matrix = zeros(number_of_buckets,number_of_buckets);

    average_accuracy = Predictions == true_class_subset.';
    for j=1:length(average_accuracy)
        accuracy_matrix(row(j),col(j)) = accuracy_matrix(row(j),col(j))+average_accuracy(j);
    end

    %now do a dot-wise division for all the categories to get a true
    %breakdown
    average_accuracy_matrix = accuracy_matrix ./ count_matrix ;

    %now create a 3d bar plot to represent the space
    figure;
    h = bar3(average_accuracy_matrix,"detached");
    hh=get(h(3),'parent');
    %[[-Inf;accuracy_buckets.'],[accuracy_buckets(1:end).';Inf]]
    set(hh,"yticklabel",strcat(string([0;accuracy_buckets.']),"-",string([accuracy_buckets.';100])," accuracy"));
    set(hh,"xticklabel",strcat(string([0;accuracy_buckets.']),"-",string([accuracy_buckets.';100])," accuracy"));
    zlabel("Average Accuracy")
    xlabel("Accuracy of Left Cluster")
    ylabel("Accuracy of right Cluster")
    zlim([0,1])
    title("Difficulty range from "+string(difficulty_buckets(i))+"-"+string(difficulty_buckets(i+1)))

  
end
% y_labels = "accuracy";
% x_labels = strcat(string(difficulty_buckets(1:end-1)),"-",string(difficulty_buckets(2:end)));
% heatmap(x_labels,y_labels,accuracy_per_bucket);
    function Y = predictTwin(netLocal, X1Local, X2Local)
        s1 = predict(netLocal, X1Local);
        s2 = predict(netLocal, X2Local);
        Y  = sigmoid(s1 - s2);
    end
end