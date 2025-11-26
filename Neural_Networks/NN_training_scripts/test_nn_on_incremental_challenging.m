function [accuracy,net] = test_nn_on_incremental_challenging(training_data,validation_data,layers,batch_size)


if class(training_data)~= "table"
    data_to_put_into_neural_network = array2table(training_data);
else
    data_to_put_into_neural_network = training_data;
end

if class(validation_data)~= "table"
    validation_data_to_put_into_neural_network = array2table(validation_data);
else
    validation_data_to_put_into_neural_network = validation_data;
end


data_to_put_into_neural_network = convertvars(data_to_put_into_neural_network,data_to_put_into_neural_network.Properties.VariableNames(end),"categorical");
validation_data_to_put_into_neural_network = convertvars(validation_data_to_put_into_neural_network,validation_data_to_put_into_neural_network.Properties.VariableNames(end),"categorical");

label_name = validation_data_to_put_into_neural_network.Properties.VariableNames(end);





number_of_validation_observations = floor(0.5* size(validation_data_to_put_into_neural_network,1));
number_of_test_observations = size(validation_data_to_put_into_neural_network,1) - number_of_validation_observations;


idx_of_testing_data = randperm(size(validation_data_to_put_into_neural_network,1),number_of_test_observations);
idx_of_validation_data = setdiff(1:size(validation_data_to_put_into_neural_network,1),idx_of_testing_data);


training_data =data_to_put_into_neural_network;
validation_data = validation_data_to_put_into_neural_network(idx_of_validation_data,:);
testing_data = validation_data_to_put_into_neural_network(idx_of_testing_data,:);





mini_batch_size = batch_size;

%    

options = trainingOptions("adam", ...
    MiniBatchSize=mini_batch_size, ...
    Shuffle="every-epoch", ...
    OutputFcn=@(info) custom_early_stop(info),...
    ValidationData={table2array(validation_data(:,1:end-1)),table2array(validation_data(:,end))},...
    Plots="none",...
    Metrics="accuracy", ...
    Verbose=true, ...
    maxEpochs=50);
%disp(training_data);
net = trainnet(table2array(training_data(:,1:end-1)),table2array(training_data(:,end)),layers,"crossentropy",options);

scores = predict(net,table2array(testing_data(:,1:end-1)));

[~,YPred] = max(scores,[],2); 
YPred = YPred-1;

YTest = testing_data{:,label_name};
accuracy = sum(categorical(YPred)== YTest)/numel(YTest);


end