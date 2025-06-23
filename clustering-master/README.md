# Graybiel Spikesorting

Unsupervised spikesorting

## Getting Started

First, add this directory and all subdirectories (except .git) to your MATLAB path.

Check `conf/spikesort_config`.

Then just run the function `run_spikesort('/path/to/your/NTT/session')`

## Structure

You will notice that there are categories of functions, each in its own subdirectory:

- `conf`: The location of the configuration file
- `core`: The core algorithm
- `gradings`: Computing cluster grades
- `main`: The main driving code which puts everything together
- `plotting`: Visualizing the data in MATLAB (WIP)
- `postprocessing`: Anything that happens after the main clustering stage
- `preprocessing`: Noise removal and other preprocessing
- `util`: Huge directory of general-purpose functions used in other parts of the spikesorting