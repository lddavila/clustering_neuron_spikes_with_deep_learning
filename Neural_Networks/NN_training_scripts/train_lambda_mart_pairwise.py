import numpy as np
import pandas as pd
import lightgbm as lgb
import matplotlib.pyplot as plt
from pathlib import Path
from typing import Tuple

# ------------------------------------------------------------
# 1. Utilities
# ------------------------------------------------------------

def build_pairwise_dataset_stratified(
    df: pd.DataFrame,
    features_to_drop: list[str],
    difficulty_bins: list[float],
    pairs_per_bin: int,
    random_state: int = 0,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    """
    Build a pairwise ranking dataset for LambdaMART where the pairs are
    stratified by choice difficulty |acc_i - acc_j|.

    Parameters
    ----------
    df : DataFrame
        Must contain an 'accuracy' column + feature columns.
    features_to_drop : list[str]
        Columns that are not used as features.
    difficulty_bins : list[float]
        Bin boundaries for |acc_i - acc_j|, e.g. [0, 5, 10, 20, 100].
        Intervals are [b0, b1), [b1, b2), ..., [b_{k-1}, b_k].
    pairs_per_bin : int
        Target number of pairs to sample in EACH difficulty bin.
    random_state : int
        RNG seed.

    Returns
    -------
    X : (2 * n_pairs_eff, n_features) array
        Feature matrix (two rows per query).
    y : (2 * n_pairs_eff,) array
        Relevance labels: 1 for better cluster, 0 for worse.
    group : (n_pairs_eff,) array
        Group sizes for LightGBM; will be all 2s.
    """
    rng = np.random.default_rng(random_state)

    df = df.reset_index(drop=True)
    accuracies = df["accuracy"].to_numpy()
    n = len(df)

    # Precompute feature matrix
    X_all = df.drop(columns=features_to_drop).to_numpy()

    # Storage
    X_pairs_all = []
    y_pairs_all = []
    group_all = []

    # Iterate over difficulty bins
    for bin_idx in range(len(difficulty_bins) - 1):
        low = difficulty_bins[bin_idx]
        high = difficulty_bins[bin_idx + 1]

        X_pairs_bin = []
        y_pairs_bin = []
        group_bin = []

        n_generated = 0
        max_trials = pairs_per_bin * 20  # generous rejection budget
        trials = 0

        while n_generated < pairs_per_bin and trials < max_trials:
            i = rng.integers(0, n)
            j = rng.integers(0, n)
            trials += 1
            if i == j:
                continue

            acc_i = accuracies[i]
            acc_j = accuracies[j]
            diff = abs(acc_i - acc_j)

            # Skip ties or pairs outside this difficulty bin
            if acc_i == acc_j:
                continue
            if not (low <= diff < high):
                continue

            # Order so that first item is the better one
            if acc_i > acc_j:
                X_pairs_bin.append(X_all[[i, j], :])
                y_pairs_bin.append([1, 0])
            else:
                X_pairs_bin.append(X_all[[j, i], :])
                y_pairs_bin.append([1, 0])

            group_bin.append(2)
            n_generated += 1

        if n_generated == 0:
            print(f"[WARN] Bin [{low}, {high}) produced 0 pairs.")
            continue
        if n_generated < pairs_per_bin:
            print(
                f"[WARN] Bin [{low}, {high}) produced only "
                f"{n_generated} pairs (target {pairs_per_bin})."
            )

        X_pairs_all.extend(X_pairs_bin)
        y_pairs_all.extend(y_pairs_bin)
        group_all.extend(group_bin)

    if not X_pairs_all:
        raise RuntimeError("No pairs were generated in any difficulty bin.")

    X = np.vstack(X_pairs_all)
    y = np.array(y_pairs_all).ravel()
    group = np.array(group_all, dtype=int)

    return X, y, group


def pairwise_accuracy_from_pairs(
    model: lgb.LGBMRanker,
    X: np.ndarray,
    y: np.ndarray,
    group: np.ndarray,
) -> float:
    """
    Compute pairwise accuracy when each query has exactly 2 items.

    Parameters
    ----------
    model : trained LGBMRanker
    X : (2 * n_pairs, n_features)
    y : length 2 * n_pairs (values 0 or 1)
    group : length n_pairs, all 2

    Returns
    -------
    float
        Fraction of pairs where the model orders the items correctly.
    """
    scores = model.predict(X)
    assert group.ndim == 1 and np.all(group == 2)

    correct = 0
    total = len(group)

    idx = 0
    for g in group:
        # g should be 2
        s_pair = scores[idx:idx + g]
        y_pair = y[idx:idx + g]
        # Ground truth: item with y=1 should have higher score
        # If model predicts same order, count as correct
        better_idx_true = int(np.argmax(y_pair))
        better_idx_pred = int(np.argmax(s_pair))
        if better_idx_true == better_idx_pred:
            correct += 1
        idx += g

    return correct / total


# ------------------------------------------------------------
# 2. Main pairwise pipeline
# ------------------------------------------------------------

if __name__ == "__main__":

    # 2.1 Load data
    csv_path = Path(
        r"C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning"
        r"\Default_Results_Dir\lambda_mart_features.csv"
    )
    data = pd.read_csv(csv_path)

    # 2.2 Train / val / test split by recording (same logic as before)
    train_mask = (
        (data["recording"] == "6_600Neuron300SecondRecordingWithLevel6Noise")
        | (data["recording"] == "7_600Neuron300SecondRecordingWithLevel7Noise")
        | (data["recording"] == "8_600Neuron300SecondRecordingWithLevel8Noise")
    )
    val_mask = data["recording"] == "9_600Neuron300SecondRecordingWithLevel9Noise"
    test_mask = data["recording"] == "10_600Neuron300SecondRecordingWithLevel10Noise"

    train_df = data[train_mask].reset_index(drop=True)
    val_df = data[val_mask].reset_index(drop=True)
    test_df = data[test_mask].reset_index(drop=True)

    print("Train clusters:", len(train_df))
    print("Val clusters  :", len(val_df))
    print("Test clusters :", len(test_df))

    # 2.3 Define which columns are NOT features
    #     (adapt to your dataframe if needed)
    features_to_drop = [
        "recording",
        "accuracy",
        "z_score",
        "tetrode",
        "cluster",
    ]

    # Drop any non-existing cols safely
    features_to_drop = [c for c in features_to_drop if c in train_df.columns]

    # 2.4 Build pairwise datasets
    # Choose how many random pairs to use; adjust as needed.
    N_PAIRS_TRAIN = 50_000
    N_PAIRS_VAL = 5_000
    N_PAIRS_TEST = 5_000

    # Define difficulty bins in terms of |accuracy_i - accuracy_j|
    # Tune these numbers based on your accuracy distribution.
    difficulty_bins = [1, 5, 10, 20, 100]   # 4 difficulty bands
    

    pairs_per_bin_train = 15_000    # total pairs ≈ 4 * 15k = 60k
    pairs_per_bin_val   = 3_000
    pairs_per_bin_test  = 3_000

    X_train, y_train, group_train = build_pairwise_dataset_stratified(
        train_df,
        features_to_drop=features_to_drop,
        difficulty_bins=difficulty_bins,
        pairs_per_bin=pairs_per_bin_train,
        random_state=0,
    )

    X_val, y_val, group_val = build_pairwise_dataset_stratified(
        val_df,
        features_to_drop=features_to_drop,
        difficulty_bins=difficulty_bins,
        pairs_per_bin=pairs_per_bin_val,
        random_state=1,
    )

    X_test, y_test, group_test = build_pairwise_dataset_stratified(
        test_df,
        features_to_drop=features_to_drop,
        difficulty_bins=difficulty_bins,
        pairs_per_bin=pairs_per_bin_test,
        random_state=2,
    )


    print("Pairwise train X shape:", X_train.shape)
    print("Pairwise val   X shape:", X_val.shape)
    print("Pairwise test  X shape:", X_test.shape)

    # 2.5 Define and train pairwise LambdaMART model
    model = lgb.LGBMRanker(
        objective="lambdarank",
        metric="ndcg",
        label_gain=[0, 1],  # relevance 0 or 1
        n_estimators=2000,
        learning_rate=0.05,
        num_leaves=31,
        verbose=-1,
    )

    model.fit(
        X=X_train,
        y=y_train,
        group=group_train,
        eval_set=[(X_val, y_val)],
        eval_group=[group_val],
        eval_at=[2],              # NDCG@2 is natural for pairwise queries
    )

    print("Best iteration:", model.best_iteration_)

    # 2.6 Inspect validation learning curve (ndcg@2)
    results = model.evals_result_
    print("Eval keys:", results.keys())
    print("Valid metrics:", results["valid_0"].keys())  # expect 'ndcg@2' or similar

    ndcg_vals = results["valid_0"]["ndcg@2"]
    plt.figure()
    plt.plot(ndcg_vals)
    plt.xlabel("Iteration")
    plt.ylabel("Validation NDCG@2")
    plt.title("Pairwise LambdaMART Validation Curve")
    plt.show()

    # 2.7 Evaluate pairwise accuracy on validation and test
    val_pair_acc = pairwise_accuracy_from_pairs(model, X_val, y_val, group_val)
    test_pair_acc = pairwise_accuracy_from_pairs(model, X_test, y_test, group_test)

    print(f"Validation pairwise accuracy: {val_pair_acc:.4f}")
    print(f"Test pairwise accuracy      : {test_pair_acc:.4f}")
