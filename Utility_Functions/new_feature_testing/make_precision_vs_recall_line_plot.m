% Load one recording's saved results
comparison_statistics = importdata("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\TP_FP_TN_FN_Results\1_600Neuron300SecondRecordingWithLevel1Noise.mat");

tp_array = comparison_statistics.tp_array;
tn_array = comparison_statistics.tn_array;
fp_array = comparison_statistics.fp_array;
fn_array = comparison_statistics.fn_array;

all_possible_certainties = .95:-0.05:.50;
number_of_neural_nets_that_must_agree = 1:1:5;

f = figure;
hold on;

for j = 1:size(tp_array,1)   % each NN agreement setting

    precision_vals = zeros(1, size(tp_array,2));
    recall_vals    = zeros(1, size(tp_array,2));

    for k = 1:size(tp_array,2)   % each certainty threshold

        tp = sum(squeeze(tp_array(j,k,:)));
        fp = sum(squeeze(fp_array(j,k,:)));
        fn = sum(squeeze(fn_array(j,k,:)));

        if tp + fp == 0
            precision_vals(k) = NaN;
        else
            precision_vals(k) = tp / (tp + fp);
        end

        if tp + fn == 0
            recall_vals(k) = NaN;
        else
            recall_vals(k) = tp / (tp + fn);
        end
    end

    plot(recall_vals, precision_vals,'DisplayName', string(number_of_neural_nets_that_must_agree(j)) + " NNs");
end

xlabel("Recall (higher indicates complete group formation)");
ylabel("Precision (higher precision indicates the merge quality increases)");
title("Precision-Recall Curve");
legend("Location","best");
grid on;
hold off;