function layers = makeTinyCNN(inputSize, numClasses, numBlocks, baseFilters, fcUnits)
    layers  = [ imageInputLayer(inputSize) ];
    filters = baseFilters;

    for b = 1:numBlocks
        % Pick kernel size: 5x5 for the first block, then 3x3
        if b == 1
            k = 5;
        else
            k = 3;
        end

        layers = [layers, ...
            convolution2dLayer(k, filters, 'Padding','same'), ...
            batchNormalizationLayer, reluLayer, ...
            maxPooling2dLayer(2, 'Stride', 2) ];

        filters = filters * 2;  % e.g., 16→32→64
    end

    layers = [layers, ...
        fullyConnectedLayer(fcUnits), reluLayer, ...
        fullyConnectedLayer(numClasses), ...
        softmaxLayer ];
end
