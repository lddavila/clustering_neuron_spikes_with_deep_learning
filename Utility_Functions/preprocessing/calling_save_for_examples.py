import MEArec as mr
import numpy as np
import matplotlib.pylab as plt
import spikeinterface.extractors as se
import spikeinterface.sorters as ss
import spikeinterface.widgets as sw
import spikeinterface.comparison as sc
import numpy as np
import pandas as pd 
import matplotlib.pyplot as plt
import spikeinterface.full as si
from scipy.io import savemat
import os
from extract_recordings import extract_recordings

# get a list of all h5 files in the current directory
list_of_files = [f for f in os.listdir(os.getcwd()) if f.endswith('.h5')]

#remove the template file from the list
list_of_files.remove("templates_300_neuropixels.h5")

#print the list of files to ensure we got it right
print("List of files to process: ", list_of_files)

#now process each file in a for loop
for i in list_of_files:
    print("Processing file: ", i)
    recording = os.path.join(os.getcwd(),i)
    print("Finished setting recording path")
    extract_recordings(recording,os.path.join(os.getcwd(),i.split(".h5")[0]))
    print("Finished extracting recording: ", i);

