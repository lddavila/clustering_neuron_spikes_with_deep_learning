import numpy as np
import lightgbm as lgb

# MATLAB passes these in pyrunfile(...):
# grades_of_cluster_groups  -> numeric matrix (n_items x n_features)
# fp_to_lambdamart_model    -> path to model file

X = np.array(grades_of_cluster_groups, dtype=float)

# Load model
# If you saved via Booster.save_model(), use Booster(model_file=...)
# If you saved via pickle/joblib, load accordingly.
model = lgb.Booster(model_file=str(fp_to_lambdamart_model))

# Predict scores
scores = model.predict(X)



# Sort indices by descending score (best first)
sorted_positions = np.argsort(scores)[::-1]
sorted_positions = sorted_positions + 1

        

        