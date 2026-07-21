function new_clustering_data = get_a_subsample_of_clustering_data(clustering_data)

desired_z_score = 2.576;      % Two-sided 99% confidence
margin_of_error = 0.01;       % 1% margin of error
population_proportion = 0.5;  % Conservative assumption

population_size = size(clustering_data, 1);

if population_size == 0
    new_clustering_data = clustering_data;
    return
end

% Sample size for an effectively infinite population
initial_sample_size = (desired_z_score^2 * population_proportion *(1 - population_proportion)) / margin_of_error^2;

% Finite-population correction
final_sample_size = ceil(initial_sample_size / (1 + (initial_sample_size - 1) / population_size));

% Cannot select more unique rows than exist
final_sample_size = min(final_sample_size, population_size);

rng(0);  % Remove if a different subsample is wanted on every call

random_idxs = randperm(population_size, final_sample_size);
new_clustering_data = clustering_data(random_idxs, :);

end