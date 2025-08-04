function [accuracy,net,layers] = predict_acc_cat_using_leaky_relu(features,num_neurons_per_layer,num_layers)



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



% NN architecture

layers = [featureInputLayer(num_features)];
for i=1:num_layers
    layers = [layers,fullyConnectedLayer(num_neurons_per_layer),leakyReluLayer];
end
layers = [layers,fullyConnectedLayer(num_classes),...
    softmaxLayer];
mini_batch_size = 32;


options = trainingOptions("adam", ...
    MiniBatchSize=mini_batch_size, ...
    Shuffle="every-epoch", ...
    ValidationData=validation_data, ...
    Metrics="accuracy", ...
    Verbose=true, ...
    maxEpochs=50);

options = trainingOptions("adam", ...
    MiniBatchSize=mini_batch_size, ...
    Shuffle="every-epoch", ...
    ValidationData=validation_data, ...
    Plots="none",...
    Metrics="accuracy", ...
    Verbose=true, ...
    maxEpochs=50);

net = trainnet(training_data,layers,"crossentropy",options);

scores = minibatchpredict(net,testing_data,MiniBatchSize=mini_batch_size);
YPred = scores2label(scores,class_names);

YTest = testing_data{:,label_name};
accuracy = sum(YPred == YTest)/numel(YTest);
% disp("accuracy:"+string(accuracy));

% figure
% confusionchart(YTest,YPred)
% disp("Finished Training NN")
close all;
end