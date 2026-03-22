# Fully Automated Spike-Sorting With Deep Learning
Spike-Sorting is the method of trying to identify specific neuron activity from raw electrodes 
## Main Directories Explanation
### clustering-master
### Data
### Default_Results_Dir
### examples
**Purpose**

### Grading_scripts
**Purpose:**
### GUI
**Purpose:**
### Neural_Networks
**Purpose:**
### plotting_functions
**Purpose:**
### Q_Learning_agent
**Purpose:**
### Shampe_Template_PNGs
**Purpose:**
### test_other_spike_sorters
**Purpose:**
### Utility Functions
**Purpose:**

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
            | timestamps
                -timestamps.mat

## What do I need to know about the config?

## What MATLAB version do I need?
    1. This pipeline was built with MATLAB 2023b, it should work with this version and newer
## What MATLAB libraries should I install
    The following MATLAB libraries are REQUIRED to be installed for the pipeline to run
        1. 

## What OS should I use?
    The majority of the pipeline was developed on windows 11, but linux and mac devices have also been tested and do not show any signs of faliure provided that the 

## What MATLAB libraries do I need?

## What will my results look like?

## Where can I find an example of the script I want to run?

## What if I have access to a high-performance cluster?