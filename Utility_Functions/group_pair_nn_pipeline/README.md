# Group-pair neural-network inference pipeline

This folder applies the trained nine-feature group-pair neural network to a
blind-pass table. The network was trained with simulated recording 10 and is
used as a postprocessing step after the five-network ensemble.

The pipeline does the following:

1. Loads the blind-pass table.
2. Uses the ensemble networks to compare every valid cluster pair and build a
   complete binary merge matrix.
3. Applies the selected spike-count and accuracy filters without rebuilding
   the complete matrix.
4. Uses `remove_conflicts` to create conservative starting groups.
5. Calculates the same nine group-pair features used during training.
6. Normalizes those features with the saved training mean and standard
   deviation.
7. Uses the trained network to calculate a merge probability for every pair of
   starting groups.
8. Regroups them using the saved probability and support cutoffs.
9. Saves one summary row for every requested accuracy cutoff.

The original ensemble networks and postprocessing functions are not modified.

## Files needed to run it

- `inference/run_group_pair_nn_pipeline.m`
- Everything inside `inference/private`
- `Neural_Networks/group_pair_nn/group_pair_nn_rec10_9_features.mat`

The MAT file contains the trained network, the nine feature names, the training
normalization values, and the selected probability and support cutoffs. It does
not contain the large training dataset or millions of saved pair probabilities.

## Input

The input MAT file must contain a table named `data_to_save`. The table needs
timestamps, `mean_waveform_rep_wire_1`, and representative-channel information.
The representative channel may be stored directly or inside `grades`.

Accuracy and `Max_Overlap_Unit` are optional. When they are present, the output
includes purity, retained units, fragmentation, and the groups-per-unit ratio.
Without them, inference still runs, but those ground-truth measurements are
reported as unavailable.

## Run from MATLAB

Start MATLAB in the repository root and run:

```matlab
addpath(genpath(fullfile(pwd, "Utility_Functions", ...
    "group_pair_nn_pipeline", "inference")));

bp_table_file = "/full/path/to/blind_pass_table.mat";

summary = run_group_pair_nn_pipeline(bp_table_file, ...
    MinimumSpikes=170, ...
    AccuracyCutoffs=0:5:100, ...
    NumberOfWorkers=6);
```

`AccuracyCutoffs` controls the experimental accuracy filter. Set it to one
number to run one cutoff, or use a vector such as `0:5:100` for a sweep. If the
input table does not have ground-truth accuracy, set `AccuracyCutoffs=0`.

The first run can take a long time because it builds the complete ensemble
matrix and scores all starting-group pairs. Progress is saved so an interrupted
run can continue. Later cutoff tests reuse the saved matrix and probabilities.

## Nine network inputs

Each row compares two `remove_conflicts` groups:

1. Timestamp overlap relative to the smaller group.
2. Timestamp overlap relative to the larger group.
3. Number of matched timestamps.
4. Euclidean distance between the average rep-wire-1 waveforms.
5. Physical distance between average representative-wire locations.
6. Number of clusters in the left group.
7. Number of clusters in the right group.
8. Number of unique timestamps in the left group.
9. Number of unique timestamps in the right group.

The network does not receive accuracy or `Max_Overlap_Unit`. Those values are
used only to filter simulated data or evaluate results when ground truth is
available.

## Output

Results are written below `Default_Results_Dir/group_pair_nn_inference` unless a
different output folder is passed to the function. The saved results include
the complete merge matrix, progress files, group-pair probabilities, final
groups for each cutoff, and a summary table.

Purity and group count should be reviewed together. A result with very high
purity can still leave one neuron split across many groups, while aggressive
merging can reduce the group count and introduce contamination.
