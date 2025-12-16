def sort_grouped_clusters(grades_of_cluster_groups,fp_to_lambdamart_model):
    """
    Sorts groups of clusters using a pre-trained LambdaMART model.

    Parameters:
    - grades_of_cluster_groups: List of DataFrames, each containing features of clusters in a group.
    - fp_to_lambdamart_model: File path to the pre-trained LambdaMART model.

    Returns:
    - sorted_cluster_groups: List of DataFrames with clusters sorted by predicted relevance.
    """
    import lightgbm as lgb
    import pandas as pd

    # Load the pre-trained LambdaMART model
    model = lgb.load(filename =fp_to_lambdamart_model)

    sorted_cluster_groups = []

    X = grades_of_cluster_groups
    
    # Predict relevance scores using the LambdaMART model
    predicted_scores = model.predict(X)

    # Add predicted scores to the DataFrame
    cluster_group_df = cluster_group_df.copy()
    cluster_group_df["predicted_score"] = predicted_scores

    # Sort clusters by predicted scores in descending order
    sorted_group_df = cluster_group_df.sort_values(by="predicted_score", ascending=False).reset_index(drop=True)

    # Append sorted DataFrame to the result list
    sorted_cluster_groups.append(sorted_group_df)

    return sorted_cluster_groups

    for cluster_group_df in grades_of_cluster_groups:
        # Prepare features by dropping non-feature columns
        features_to_drop = [
            "recording",
            "accuracy",
            "z_score",
            "tetrode",
            "cluster",
        ]
        features_to_drop = [c for c in features_to_drop if c in cluster_group_df.columns]
        

        