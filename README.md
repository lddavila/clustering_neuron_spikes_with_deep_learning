# Fully Automated Spike-Sorting With Deep Learning
Spike-Sorting is the method of trying to identify specific neuron activity from raw electrodes 
## Main Directories Explanation

### project_root_directory
- **Location:** \clustering_neuron_spikes_with_deep_learning
- **Purpose:** houses the entire pipeline
### clustering-master
- **Location:** \clustering_neuron_spikes_with_deep_learning\
- **Purpose:** Houses the clustering logic of the algorithm
### Data
- **Location:** clustering_neuron_spikes_with_deep_learning\Data
- **Purpose:** This is expected to be the directory where raw data lives. Any data used by examples script is also downloaded here by the download function.
### Default_Results_Dir
- **Location**: clustering_neuron_spikes_with_deep_learning\Default_Results_Dir
- **Purpose**: This directory is the default output directory for any results the pipeline runs
### examples
- **Location** \clustering_neuron_spikes_with_deep_learning\examples\
- **Purpose** This directory contains several example scripts for running the pipeline
### Grading_scripts
- **Location:** \clustering_neuron_spikes_with_deep_learning\Grading_scripts
- **Purpose:**
### GUI
- ***Location:** \clustering_neuron_spikes_with_deep_learning\GUI
- **Purpose:** contains a rudimentary GUI which is capable of running the pipeline without the use of scripts
### Neural_Networks
- ***Location:** \clustering_neuron_spikes_with_deep_learning\Neural_Networks
- **Purpose:**
### plotting_functions
- ***Location:** \clustering_neuron_spikes_with_deep_learning\plotting
- **Purpose:**
### Shampe_Template_PNGs
- ***Location:** \clustering_neuron_spikes_with_deep_learning\Shape_Template_PNGs
- **Purpose:**
### test_other_spike_sorters
- ***Location:** \clustering_neuron_spikes_with_deep_learning\test_other_spike_sorters
- **Purpose:**
### Utility Functions
- ***Location:** \clustering_neuron_spikes_with_deep_learning\Utility_Functions
- **Purpose:**

## What should my Data Look Like?
    1. Our pipeline expects your data to be structured into a folder 
    '-' indicates a file
    '|' indicates a directory
    '%' a comment about the data not an actual file
        folder_with_all_data
            | ground truth
                -ground_truth.mat
                %ground truth should be a cell array that looks like the following
                %ground_truth = {[3,4,5 ..., n],[ ...,],[],[]}
                %
            | recordings_by_channel
                -c1.mat
                -c2.mat
                -c3.mat 
                 ...
                -cn.mat 
                %n represents the max number of channels
                %every file in this directory represents a single channel of your recording
                %they should all by 1xn
                %where n represents the number of samples taken during your recording
            | timestamps
                -timestamps.mat
                -timestamps is an array full of singles or doubles

## How can I get an instance of the config
while in the root directory:[what is the root directory?](#project_root_dir)
```
addpath(genpath(fullfile(pwd,"Neural_Networks/"))); 
addpath(genpath(fullfile(pwd,"Grading_scripts")));  
addpath(genpath(fullfile(pwd,"clustering-master")));  
addpath(genpath(fullfile(pwd,"Utility_Functions")));
config = spikesort_config();
```

## What do I need to know about the config?
The config file is a MATLAB struct with many configurable fields. The main fields that most users are concerned with are listed below
```
config.RECORDING_NAME:
config.BLIND_PASS_DIR_PRECOMUTED:
config.BLIND_PASS_DIR_PRECOMPUTED_ONLY_END:

```

## What MATLAB version do I need?
    1. This pipeline was built with MATLAB 2023b, it should work with this version and newer

## What OS should I use?
The majority of the pipeline was developed on windows 11, but linux and mac devices have also been tested and do not show any signs of faliure provided that the appropriate matlab instance and packages are installed.

## What MATLAB libraries do I need?
The following packages are necessary for the pipeline to work, and should be installed when installing matlab to your local machine.

- "Medical Imaging Toolbox"                    "23.2"      true         "DX"   
- "Database Toolbox"                           "23.2"      true         "DB"   
- "MATLAB Compiler"                            "23.2"      true         "CO"   
- "Image Processing Toolbox"                   "23.2"      true         "IP"   
- "MATLAB Coder"                               "23.2"      true         "ME"   
- "Data Acquisition Toolbox"                   "23.2"      true         "DA"   
- "Predictive Maintenance Toolbox"             "23.2"      true         "PM"   
- "Signal Processing Toolbox"                  "23.2"      true         "SG"   
- "Deep Learning Toolbox"                      "23.2"      true         "NN"   
- "Optimization Toolbox"                       "23.2"      true         "OP"   
- "Curve Fitting Toolbox"                      "23.2"      true         "CF"   
- "Statistics and Machine Learning Toolbox"    "23.2"      true         "ST"   
- "Reinforcement Learning Toolbox"             "23.2"      true         "RL"   
- "Parallel Computing Toolbox"                 "23.2"      true         "DM"   
- "System Identification Toolbox"              "23.2"      true         "ID"   
- "Partial Differential Equation Toolbox"      "23.2"      true         "PD"   
- "GPU Coder"                                  "23.2"      true         "GC"   
- "MATLAB Compiler SDK"                        "23.2"      true         "MJ"   
- "Simulink"                                   "23.2"      true         "SL"   

### How do I know if I have these packages already?
- run

addons = matlab.addons.installedAddons
to get a list of what packages your matlab installation may already have installed
## What will my results look like?

## Where can I find an example of the script I want to run?

## What if I have access to a high-performance cluster?