import numpy as np
import lightgbm as lgb

# MATLAB passes:
#   grades_of_cluster_groups: numeric matrix (n_items x n_features) OR (n_features,) if single row collapses
#   fp_to_lambdamart_model: path to model file

X = np.asarray(grades_of_cluster_groups, dtype=float)

# Guarantee 2D for LightGBM
X = np.atleast_2d(X)  # (n_samples, n_features)

# Load model
model = lgb.Booster(model_file=str(fp_to_lambdamart_model))

# Optional: validate feature dimension if model exposes it
# (Some versions expose num_feature(); if not, skip)
try:
    n_model_feat = model.num_feature()
    if X.shape[1] != n_model_feat:
        raise ValueError(f"Feature mismatch: X has {X.shape[1]} features, model expects {n_model_feat}.")
except Exception:
    pass

# Predict
scores = model.predict(X)  # shape (n_samples,)

# Sort descending (best first)
sorted_positions = np.argsort(-scores).astype(np.int64) + 1  # MATLAB 1-based

# Ensure plain numpy arrays returned to MATLAB
scores = np.asarray(scores, dtype=float)
sorted_positions = np.asarray(sorted_positions, dtype=np.int64)
        