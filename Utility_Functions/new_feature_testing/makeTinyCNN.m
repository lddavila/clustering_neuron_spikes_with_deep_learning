function layers = makeTinyCNN(inputSize, numClasses, numBlocks, baseFilters, fcUnits)
% numBlocks ∈ {2,3}, baseFilters ∈ {16,32}, fcUnits ∈ {64,128}
    layers = [ imageInputLayer(inputSize) ];
    filters = baseFilters;

    for b = 1:numBlocks
        layers = [layers, ...
            convolution2dLayer(b==1 && 5 || 3, filters, 'Padding','same'), ...
            batchNormalizationLayer, reluLayer, ...
            maxPooling2dLayer(2,'Stride',2) ];
        filters = filters * 2;  % 16→32→64 or 32→64→128
    end

    layers = [layers, ...
        fullyConnectedLayer(fcUnits), reluLayer, ...
        fullyConnectedLayer(numClasses), softmaxLayer ];
end
