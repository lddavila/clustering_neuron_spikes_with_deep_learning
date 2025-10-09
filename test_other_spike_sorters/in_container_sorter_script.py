
import json
from pathlib import Path
from spikeinterface import load
from spikeinterface.sorters import run_sorter_local

if __name__ == '__main__':
    # this __name__ protection help in some case with multiprocessing (for instance HS2)
    # load recording in container
    json_rec = Path('/Users/ldd77/OneDrive/Desktop/clustering_neuron_spikes_with_deep_learning/test_other_spike_sorters/in_container_recording.json')
    pickle_rec = Path('/Users/ldd77/OneDrive/Desktop/clustering_neuron_spikes_with_deep_learning/test_other_spike_sorters/in_container_recording.pickle')
    if json_rec.exists():
        recording = load(json_rec)
    else:
        recording = load(pickle_rec)

    # load params in container
    with open('/Users/ldd77/OneDrive/Desktop/clustering_neuron_spikes_with_deep_learning/test_other_spike_sorters/in_container_params.json', encoding='utf8', mode='r') as f:
        sorter_params = json.load(f)

    # run in container
    output_folder = '/Users/ldd77/OneDrive/Desktop/clustering_neuron_spikes_with_deep_learning/test_other_spike_sorters/spykingcircus_output'
    sorting = run_sorter_local(
        'spykingcircus', recording, folder=output_folder,
        remove_existing_folder=True, delete_output_folder=False,
        verbose=True, raise_error=True, with_output=True, **sorter_params
    )
    sorting.save(folder='/Users/ldd77/OneDrive/Desktop/clustering_neuron_spikes_with_deep_learning/test_other_spike_sorters/spykingcircus_output/in_container_sorting')
