# Group-pair neural-network pipeline

This folder contains the code used to train the nine-feature group-pair neural
network on simulated recording 10 and test the frozen network on simulated
recording 6.

The new network is a postprocessing step. The existing five-network council
first compares individual clusters and creates a binary merge matrix. The
`remove_conflicts` strategy turns that matrix into conservative starting
groups. The nine-feature network then compares pairs of those starting groups
and predicts whether each pair should merge.

The scripts here do not modify the original council networks or
`simple_grouping_parallel_ensemble.m`.

## Important limitations

- All current experiments use simulated recordings with ground truth.
- `Max_Overlap_Unit` is used to create training labels, split units, and
  evaluate results. It is never one of the nine neural-network inputs.
- Recording 10 units are split before pair rows are built: 60% training, 20%
  validation, and 20% final testing. This prevents one simulated unit from
  appearing in more than one split.
- Training uses a 50% merge / 50% do-not-merge sample. Validation uses 40%
  merge / 60% do-not-merge. Natural and balanced test tables are both saved.
- Hard negatives are mined only from training units. Validation chooses the
  probability and support policy. The held-out test units are used once for
  final evaluation.
- The recording 6 accuracy filter uses simulated ground-truth accuracy. It is
  useful for this experiment but cannot be used as a real-data quality filter.
- Results are preliminary. Purity, group count, and the groups/units ratio must
  be reviewed together, and the code still needs independent scientific review.

## Nine input features

Each dataset row compares two `remove_conflicts` groups. The network receives:

1. Timestamp overlap relative to the smaller group.
2. Timestamp overlap relative to the larger group.
3. Number of matched timestamps.
4. Euclidean distance between the average rep-wire-1 waveforms.
5. Physical distance between the groups' average representative-wire locations.
6. Number of clusters in the left group.
7. Number of clusters in the right group.
8. Number of unique timestamps in the left group.
9. Number of unique timestamps in the right group.

Every feature is normalized using the mean and standard deviation calculated
from the training rows only. The same saved values are then applied to
validation, test, and recording 6 data.

## Training on recording 10

Run the scripts in `training` in numerical order.

### Prerequisites

The first script starts from the filtered recording 10 table and binary council
merge matrix produced during the earlier postprocessing stage. Place these
local generated files at the paths set near the top of
`step_1_make_remove_conflicts_groups.m`:

- `merge_matrix_5000ish.mat`
- `readable_matrix_grouping_run.mat`

These large/generated MAT files are intentionally not stored in Git.

### Scripts

1. `step_1_make_remove_conflicts_groups.m`
   Removes ambiguous conflict clusters from the matrix, creates conservative
   starting groups, and saves their ground-truth summary.
2. `step_2_compute_timestamp_features.m`
   Compares every starting-group pair and saves timestamp overlap measurements.
3. `step_3_compute_waveform_features.m`
   Computes average group waveforms and Euclidean distances for the same pairs.
4. `step_4_build_nn_dataset.m`
   creates the 60/20/20 unit split and the train, validation, balanced-test,
   and natural-test tables.
5. `step_5_train_group_pair_nn.m`
   Trains the 9-16-8-2 network, mines training-only hard negatives, trains a new
   network from scratch, chooses a grouping policy with validation units, and
   evaluates that policy on held-out test units.
6. `analyze_test_contamination.m`
   Audits which accepted links caused contamination in the final test groups.

The main trained-model result is saved as:

`Default_Results_Dir/group_pair_nn_clear_experiment_result.mat`

## Applying the frozen network to recording 6

Place recording 6 at:

`Data/6_600Neuron300SecondRecordingWithLevel6Noise/blind_pass_table.mat`

Then run the scripts in `recording_6` in numerical order:

1. Apply the 170-spike and 15%-accuracy experimental filter.
2. Run the existing five-network council and build the cluster merge matrix.
3. Create the `remove_conflicts` starting groups.
4. Calculate and normalize all nine features for every starting-group pair.
5. Score the pairs with the frozen recording 10 network and regroup them.
6. Reuse the saved probabilities to compare stricter probability/support rules.

The expensive operations are checkpointed or saved. Steps 5 and 6 do not
recompute the five-network council matrix.

## Accuracy-cutoff experiment

The `accuracy_sweep` folder tests the same frozen network while changing only
the recording 6 ground-truth accuracy filter.

`step_1_expand_accuracy_matrix.m` reuses a completed stricter matrix and only
computes the newly added cluster pairs. It supports a 5% base built from the
15% result, or a 0% base built from the completed 5% result.

`step_2_run_accuracy_sweep.m` defaults to these cutoffs:

```matlab
[5; 15; 25; 30; 35; 40; 45; 50; 55; 70]
```

The council settings, trained network, feature normalization, merge-probability
cutoff, and support cutoff remain fixed. This isolates the effect of the
accuracy filter.

## Reported recording 6 reference

At the 15% accuracy filter:

- 11,850 raw clusters and 580 ground-truth units.
- 9,076 retained clusters and 524 retained units.
- 7,616 `remove_conflicts` groups with 99.93% fully pure groups.
- Applying the frozen network at probability 0.95 and support 0.75 produced
  516 groups for 524 retained units, with 84.69% fully pure groups and 77.37%
  of clusters in fully pure groups.

This result is close to one group per retained unit, but the contamination is
substantial. It is a tradeoff result, not a final validated operating point.

## Files intentionally left out

The clean branch does not include autosaves, poster exports, generated MAT
files, checkpoints, one-off debugging scripts, abandoned grouping strategies,
or the symmetric/shared-wire feature experiment that did not improve held-out
testing. Those files remain in the original `matrix_grouping` checkout for
reference.
