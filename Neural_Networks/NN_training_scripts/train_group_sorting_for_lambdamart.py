#this version of the function uses pre-normalized data for training
#the validation and test data are also pre-normalized by the training data stats
import sys
import os
import csv
import pandas as pd
import snowflake.connector
from sklearn.model_selection import train_test_split
import itertools
import numpy as np
import matplotlib.pyplot as plt
import lightgbm as lgb

def add_query_id(blind_pass_df):
    #this function will take a dataframe and assemble query sets that represent every availble accuracy
    #each query set will contain all possible accuracies
    #the goal being that we can train a lambda mart model to rank these sets and work generally to identify accuracy
    all_possible_accuraracies = np.unique(np.round(blind_pass_df['accuracy'].unique(),2)).tolist()
    #establish an array to see if the current cluster has already been added to a query set
    cluster_already_used = np.zeros(len(blind_pass_df), dtype=bool)
    query_id = np.full(len(blind_pass_df), np.nan)
    current_query_id = 0
    tracker_counter = 0;
    for cluster_idx in range(len(blind_pass_df)):
        if cluster_already_used[cluster_idx]:
            print("Finished "+str(cluster_idx)+"/"+str(len(blind_pass_df)))
            tracker_counter += 1
            continue

        available_accuracies = (
        np.round(blind_pass_df.loc[~cluster_already_used, "accuracy"], 2)
        .unique()
        .tolist()
    )
        for accuracy in available_accuracies:
            #print(accuracy)
            mask = (np.round(blind_pass_df["accuracy"])== np.round(accuracy)) & (~cluster_already_used)
            if not mask.any():
                continue
            #print(mask)
            idx = blind_pass_df.loc[mask].index[0]
            query_id[idx] = current_query_id
            cluster_already_used[idx] = True
            print("Finished "+str(tracker_counter)+"/"+str(len(blind_pass_df)))
            tracker_counter += 1
        current_query_id += 1
    
    #now add the query id to the dataframe
    blind_pass_df['query_id'] = query_id
    return blind_pass_df

if __name__ == "__main__":

    #import data that will be used for training
    data = pd.read_csv(r"C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\lambda_mart_features.csv")
    data.head()

    #filter the training data down to only recordings 6,7,8
    training_data = pd.read_csv(r"C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\lambda_mart_training_features_normalized.csv");

    #get the validation data to recording 9
    validation_data = pd.read_csv(r"C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\lambda_mart_val_features_normalized.csv");

    #get the test data to recording 10
    test_data = pd.read_csv(r"C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\lambda_mart_test_features_normalized.csv");

    #print heads and size of each dataset
    print("Training Data:")
    print(training_data.head())
    print("Size of Training Data:", len(training_data))
    print("Validation Data:")
    print(validation_data.head())
    print("size of Validation Data:", len(validation_data))
    print("Test Data:")
    print(test_data.head())
    print("size of Test Data:", len(test_data))

    # add query ids to each dataset
    training_data = add_query_id(training_data)
    validation_data = add_query_id(validation_data) 
    test_data = add_query_id(test_data)

    #get the true relevance classes for training, validation, and test data
    Y_train = np.round(training_data['accuracy'].to_numpy())
    Y_val = np.round(validation_data['accuracy'].to_numpy())
    Y_test = np.round(test_data['accuracy'].to_numpy())

    # rows + group lengths
    train_sorted = training_data.sort_values("query_id").reset_index(drop=True)
    val_sorted = validation_data.sort_values("query_id").reset_index(drop=True)
    test_sorted = test_data.sort_values("query_id").reset_index(drop=True)

    # drop rows that never got assigned a query_id
    train_sorted = train_sorted.dropna(subset=["query_id"])
    val_sorted = val_sorted.dropna(subset=["query_id"])
    test_sorted = test_sorted.dropna(subset=["query_id"])

    train_group = train_sorted.groupby("query_id").size().to_numpy()
    val_group = val_sorted.groupby("query_id").size().to_numpy()
    test_group = test_sorted.groupby("query_id").size().to_numpy()

    assert train_group.sum() == len(train_sorted)
    assert val_group.sum() == len(val_sorted)
    assert test_group.sum() == len(test_sorted)

    features_to_drop = ["recording", "accuracy", "z_score", "tetrode", "cluster", "query_id"]

    X_train = train_sorted.drop(columns=features_to_drop).to_numpy()
    Y_train = np.round(train_sorted["accuracy"]).astype(int) - 1
    X_val = val_sorted.drop(columns=features_to_drop).to_numpy()
    Y_val = np.round(val_sorted["accuracy"]).astype(int) - 1
    X_test = test_sorted.drop(columns=features_to_drop).to_numpy()
    Y_test = np.round(test_sorted["accuracy"]).astype(int) - 1

    model = lgb.LGBMRanker(objective="lambdarank", metric="ndcg", label_gain=list(range(100)),verbose=1, n_estimators=1000)
    model.fit(
    X=X_train,
    y=Y_train,
    group=train_group,
    eval_set=[(X_val, Y_val)],
    eval_group=[val_group],
    eval_at=100,
)
    results = model.evals_result_
    print(results.keys())            # usually ['training', 'valid_0']
    print(results['valid_0'].keys()) # see exact metric names, e.g. dict_keys(['ndcg@100'])
    plt.plot(results["valid_0"]["ndcg@100"])
    plt.xlabel("Iteration")
    plt.ylabel("NDCG@100")
    plt.savefig("lambda_mart_ndcg_curve_normalized.png")
    plt.show()

    #save the model
    model.booster_.save_model("lambda_mart_model_normalizes.txt")