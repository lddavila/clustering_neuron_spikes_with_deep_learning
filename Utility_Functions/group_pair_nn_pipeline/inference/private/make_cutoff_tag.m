function cutoff_tag = make_cutoff_tag(accuracy_cutoff)
%MAKE_CUTOFF_TAG Make a short file label for one accuracy cutoff.

if isnan(accuracy_cutoff)
    cutoff_tag = "no_accuracy_filter";
else
    cutoff_text = replace(compose("%05.1f", accuracy_cutoff), ".", "p");
    cutoff_tag = "accuracy_" + cutoff_text;
end
end
