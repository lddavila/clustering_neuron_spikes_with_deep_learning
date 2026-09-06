function [net] = train_a_net(training_data,validation_data,layers,batch_size)


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


training_data =data_to_put_into_neural_network;
validation_data = validation_data_to_put_into_neural_network;


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




end