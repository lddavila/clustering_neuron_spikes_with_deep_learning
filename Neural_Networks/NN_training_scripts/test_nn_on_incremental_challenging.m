function [accuracy,net] = test_nn_on_incremental_challenging(features,layers,batch_size)



data_to_put_into_neural_network = features;



data_to_put_into_neural_network = convertvars(data_to_put_into_neural_network,data_to_put_into_neural_network.Properties.VariableNames(end),"categorical");

label_name = data_to_put_into_neural_network.Properties.VariableNames(end);


% because we don't actually know what probability of cluster accuracy will be 
%i'll find the least common one and randomly sample all categories to match that appearence
%my hope is that this will generalize better 



class_names = categories(data_to_put_into_neural_network{:,label_name});
num_classes = length(class_names);
num_features = size(features,2)-1;

number_of_observations = size(data_to_put_into_neural_network,1);
number_of_training_observations = floor(0.7 * number_of_observations);
number_of_validation_observations = floor(0.15 * number_of_observations);
number_of_test_observations = number_of_observations - number_of_validation_observations - number_of_training_observations;

rng("default");
idx = randperm(number_of_observations);
idx_of_training_data = idx(1:number_of_training_observations);
idx_of_validation_data = idx(number_of_training_observations+1:number_of_training_observations+number_of_validation_observations);
idx_of_testing_data = idx(number_of_training_observations+number_of_validation_observations+1:end);


training_data = data_to_put_into_neural_network(idx_of_training_data,:);
validation_data = data_to_put_into_neural_network(idx_of_validation_data,:);
testing_data = data_to_put_into_neural_network(idx_of_testing_data,:);

%add one hot encoding to all the data




mini_batch_size = batch_size;



options = trainingOptions("adam", ...
    MiniBatchSize=mini_batch_size, ...
    Shuffle="every-epoch", ...
    ValidationData={table2array(validation_data(:,1:end-1)),table2array(validation_data(:,end))},...
    Plots="none",...
    Metrics="accuracy", ...
    Verbose=true, ...
    ValidationPatience=3,...
    maxEpochs=50);
%disp(training_data);
net = trainnet(table2array(training_data(:,1:end-1)),table2array(training_data(:,end)),layers,"crossentropy",options);

scores = predict(net,table2array(testing_data(:,1:end-1)));

[~,YPred] = max(scores,[],2); 
YPred = YPred-1;

YTest = testing_data{:,label_name};
accuracy = sum(categorical(YPred)== YTest)/numel(YTest);
end