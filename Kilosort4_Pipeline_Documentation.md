# Kilosort4 Grading Pipeline Full Documentation

**Author:** Srijon Mandal

**Purpose:** Automated grading of Kilosort4 spike sorting outputs against ground truth data, producing a blind pass table of cluster-level accuracy and quality grades across all tetrodes in a recording.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Repository Structure](#2-repository-structure)
3. [Data Folder Layout](#3-data-folder-layout)
4. [Dependencies and Setup](#4-dependencies-and-setup)
5. [Configuration](#5-configuration)
6. [File-by-File Reference](#6-file-by-file-reference)
   - [run_grader.m](#61-run_graderm)
   - [get_representative_channel.m](#62-get_representative_channelm)
   - [assign_templates_to_tetrodes.m](#63-assign_templates_to_tetrodesm)
   - [get_spike_indices_per_tetrode.m](#64-get_spike_indices_per_tetrodem)
   - [extract_waveform_snippets.m](#65-extract_waveform_snippetsm)
7. [Adding a New Recording](#10-adding-a-new-recording)
8. [Troubleshooting](#11-troubleshooting)

---

## 1. Overview

This pipeline takes raw Kilosort4 spike sorting results and systematically grades every detected cluster across every tetrode in a recording. It is designed to run fully automatically with no hard-coded values since all recording-specific details (number of templates, number of spikes, number of tetrodes, channel assignments) are read from data files at runtime.

The pipeline performs the following high-level operations for each recording:

1. Loads Kilosort4 sorter outputs (templates, spike assignments, spike times)
2. Loads the continuous voltage traces and timestamps
3. Loads ground truth agreement scores
4. Determines which Kilosort template "belongs" to which tetrode based on which channel has the largest amplitude response
5. Extracts voltage waveform snippets around each detected spike
6. Interpolates and peak-aligns those waveforms
7. Calls the lab's grading function on each tetrode's aligned waveforms
8. Looks up the accuracy for each cluster from the agreement scores CSV
9. Computes the waveforms 
9. Saves a final blind pass table with one row per cluster: tetrode, cluster ID, accuracy, grades, waveforms

Grading is **checkpointed per tetrode**, so if the pipeline is interrupted mid-run, it will resume from the last completed tetrode rather than starting over.

---

## 2. Repository Structure

All `.m` files must be in the same folder (or on the MATLAB path). The current directory when running `run_grader.m` must be the folder containing it.

```
<project_root>/
│
├── run_grader.m (**main script, run this**)
├── get_representative_channel.m    
├── assign_templates_to_tetrodes.m
├── get_spike_indices_per_tetrode.m 
├── extract_waveform_snippets.m 
├── get_template_spike_idx_and_ts_for_clusters_kilosort4.m  
│
├── interpolate_spikes.m          
├── align_to_peak_ver_2.m            
├── compute_gradings_ver_4.m        
├── draw_elipse_templates.m      
│
└── Data/
    ├── 1_600Neuron300SecondRecordingWithLevel1Noise/
    │   ├── recordings_by_channel/
    │   │   ├── c1.mat
    │   │   ├── c2.mat
    │   │   └── ...
    │   └── timestamps/
    │       └── timestamps.mat
    │
    └── 1_600Neuron300SecondRecordingWithLevel1Noise_resultskilosort4/
        ├── sorter_output/
        │   ├── templates.npy
        │   ├── spike_templates.npy
        │   └── spike_times.npy
        └── agreement_scores.csv
```

---

## 3. Data Folder Layout

Each recording consists of **exactly two sibling folders** inside `Data/`. They share the same base name, and one has the suffix `_resultskilosort4`.

### Raw recording folder — `<N>_<RecordingName>/`

Contains the continuous electrophysiology data:

| Sub-path | Contents |
|---|---|
| `recordings_by_channel/c<K>.mat` | Voltage trace for channel K. Each `.mat` contains a single variable (named `c<K>`) of size `[nSamples x 1]` double. |
| `timestamps/timestamps.mat` | Contains a variable named `timestamps` of size `[1 x nSamples]` in seconds. This is the time axis shared by all channels. |

### Sorter results folder — `<N>_<RecordingName>_resultskilosort4/`

Contains Kilosort4 outputs and ground truth comparison:

| Sub-path | Contents |
|---|---|
| `sorter_output/templates.npy` | Template waveforms. Shape: `[nTemplates x nTimepoints x nChannels]`. Example: `[1511 x 61 x 384]`. |
| `sorter_output/spike_templates.npy` | Template assignment for every spike. Shape: `[nSpikes x 1]`. Values are **0-based** Kilosort cluster IDs (0 to nTemplates−1). Example: `[2233612 x 1]`. |
| `sorter_output/spike_times.npy` | Time of every spike in seconds. Shape: `[nSpikes x 1]`. Parallel array to `spike_templates.npy`. |
| `agreement_scores.csv` | Agreement score matrix between Kilosort clusters and ground truth neurons. Row 1 is a header. Column 1 is the **0-based** cluster ID. Columns 2 onward are agreement scores (0–1) against each ground truth unit. Shape: `[nClusters+1 x nGroundTruthUnits+1]` including the header row and ID column. |

> **Important:** `agreement_scores.csv` lives directly inside the `_resultskilosort4` folder, **not** inside `sorter_output/`.

---

## 4. Dependencies and Setup

### Required MATLAB toolboxes
- Signal Processing Toolbox 

### Required external utilities

**npy-matlab** — needed to read `.npy` files from Python/NumPy format into MATLAB.

Download from: https://github.com/kwikteam/npy-matlab

After downloading, add it to your MATLAB path:
```matlab
addpath('/path/to/npy-matlab');
savepath;  % optional: makes it permanent
```

The pipeline will error immediately with a clear message if `readNPY` is not found on the path.

### Required lab-provided functions

The following four functions are from the repository and must be on the MATLAB path. The pipeline calls them but does not define them:

| Function | Called at | Purpose |
|---|---|---|
| `interpolate_spikes(spikes, config_struct)` | Upsamples spike waveforms from 61 to 120 time points |
| `align_to_peak_ver_2(spikes, [], [])` | Aligns all waveforms to their peak sample |
| `draw_elipse_templates(config_struct)` | Draws ellipse template figures before grading |
| `compute_gradings_ver_4(...)` | Core grading function, returns grade matrix |

### MATLAB current folder

Before running, set MATLAB's current folder to the project root path. You can set it in the MATLAB file browser or with: 
```matlab
cd('/your_unique_machine/clustering_neuron_spikes_with_deep_learning');
```
Then, execute the command `addpath(genpath(pwd))` to be able to access all the necessary files. Afterwards, execute `run_grader.m`. The script uses `pwd` to construct all paths, so this must be correct. 

---

## 5. Configuration

Three constants are defined at the top of `run_grader.m`. Edit these if your setup differs:

```matlab
DATA_DIR       = fullfile(pwd, 'Data');       % path to the Data/ folder
SORTER_SUFFIX  = '_resultskilosort4';         % suffix identifying sorter result folders
WINDOW_SAMPLES = 30;                          % samples cut either side of each spike
```

**`DATA_DIR`** — The pipeline will look for recording folder pairs inside this directory. By default it expects a folder called `Data` in the current folder.

**`SORTER_SUFFIX`** — The pipeline finds recording pairs by searching for subfolders of `Data/` whose names end with this suffix. The raw recording folder is then inferred by stripping this suffix. If the lab changes the naming convention, update this one string.

**`WINDOW_SAMPLES`** — Controls the width of the extracted voltage snippet around each spike. With `WINDOW_SAMPLES = 30`, the snippet is 61 samples wide (30 before the spike + the spike sample + 30 after). This must match what the grading and interpolation functions expect.

---

## 6. Adding a New Recording

To add a second recording (e.g. `2_600Neuron300SecondRecordingWithLevel1Noise`):

1. Create the two folders inside `Data/`:
   - `2_600Neuron300SecondRecordingWithLevel1Noise/`
     - `recordings_by_channel/` with `c1.mat`, `c2.mat`, etc.
     - `timestamps/timestamps.mat`
   - `2_600Neuron300SecondRecordingWithLevel1Noise_resultskilosort4/`
     - `sorter_output/` with `templates.npy`, `spike_templates.npy`, `spike_times.npy`
     - `agreement_scores.csv`

2. Run `run_grader.m` without any code changes.

The `dir()` wildcard search will automatically find both `_resultskilosort4` folders and process them in sequence. Each recording's outputs are saved into its own `_resultskilosort4` folder and are independent of each other. The `rec_id` variable saved inside each output file ensures results are always self-identifying.

---

## 7. Troubleshooting

**`readNPY not found`**
Add the npy-matlab toolbox to the MATLAB path. See Section 4.

**`Error using dir / Name must be a text scalar`**
Ensure `SORTER_SUFFIX` is defined as a string (double quotes) and `DATA_DIR` resolves to a non-empty path. Run `disp(DATA_DIR)` to verify. Make sure MATLAB's current folder is set to the project root before running.

**`No *_resultskilosort4 folders found`**
Verify the folder names in `Data/` end exactly with `_resultskilosort4` (no trailing space, correct capitalisation). MATLAB's `dir` is case-sensitive on Linux/Mac.

**`Unable to read file 'c97.mat'`**
The channel file does not exist in `recordings_by_channel/`. Check that the file is named exactly `c<N>.mat` and that it contains a variable named `c<N>`. If the variable inside the `.mat` has a different name, the load line `ch.(ch_name)` will fail.

**`timestamps field not found`**
The variable inside `timestamps.mat` must be named exactly `timestamps`. Load the file manually with `load('timestamps.mat')` and check the variable name in the workspace.

**Grading interrupted mid-run**
Simply re-run `run_grader.m`. The checkpoint file (`grading_checkpoint.mat`) will be detected and all completed tetrodes skipped. Only the remaining tetrodes will be processed.

**`NaN` in Accuracy column of blind pass table**
This means the cluster ID was not found in `agreement_scores.csv`. This can happen if Kilosort produced more templates than the agreement score file covers. Check that `agreement_scores.csv` was generated from the same Kilosort run as the `.npy` files.

**Snippets all being skipped (tetrode_snippets all empty)**
The spike times from `spike_times.npy` may be in sample units rather than seconds, or the timestamps vector may have a different time scale. Verify that `spike_times_raw` values (printed in the command window if you add `disp`) are in the same units as `timestamps`.
