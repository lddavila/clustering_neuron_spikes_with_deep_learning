function[classification] = category_of_cluster(low_cutoff,medium_cutoff,high_cutoff,peaks)
mean_of_cluster = mean(peaks,"all");
classification = 0;
if abs(mean_of_cluster) <= medium_cutoff
    classification = 1;
elseif abs(mean_of_cluster) > medium_cutoff && abs(mean_of_cluster) < high_cutoff
    classification =2;
elseif high_cutoff <= abs(mean_of_cluster)
    classification =3;
end
end