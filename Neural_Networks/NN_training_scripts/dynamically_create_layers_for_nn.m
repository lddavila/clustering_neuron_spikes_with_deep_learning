function [layers] = dynamically_create_layers_for_nn(num_features,num_neurons_per_layer,num_layers,num_classes)

layers = [featureInputLayer(num_features)];
for i=1:num_layers
    layers = [layers,fullyConnectedLayer(num_neurons_per_layer),leakyReluLayer];
end
layers = [layers,fullyConnectedLayer(num_classes),...
    softmaxLayer];
end