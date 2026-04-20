function [best_elipse_score,circularity] = plot_cluster_as_png_and_return_elipse_rating(compare_wire_peaks,compare_wire_2_peaks,dir_of_template_figures)

compare_wire_peaks = double(compare_wire_peaks);
compare_wire_2_peaks = double(compare_wire_2_peaks);
%it seems as though circularity below 1.7 can indicate something bad
best_elipse_score = NaN;
circularity = NaN;

if isempty(compare_wire_peaks) || isempty(compare_wire_2_peaks)
    return;
end
k = boundary(compare_wire_peaks.',compare_wire_2_peaks.',1);
% hold on;
f =figure('Visible','off');
%set(f, 'Position', [100 100 800 600]);
fill(compare_wire_peaks(k),compare_wire_2_peaks(k),'k');

axis off;
%randomized_temp_file_number_sequence = randi(1e9, 1, 10);
%file_save_name = strjoin(string(randomized_temp_file_number_sequence))+".png"; %this file will be deleted
% so we just randomly generate 10 numbers between 1 and billion and use this as a file name to avoid a multi threaded process accidentally
%reading the same file
%saveas(f,file_save_name);
frame = getframe(f);
RGB = frame2im(frame);
close(f);
%the_cluster_image = imread(file_save_name);
grayImage = rgb2gray(RGB);
binary_image = imbinarize(grayImage);

%order will always be horizontal elipse, left to right negative elipsde, left to right positive elipse, vertical elipse, circle
elipse_like_score = nan(1,4);

for i=1:size(dir_of_template_figures,1)
    template_image = imread(dir_of_template_figures(i));
    gray_template_image = rgb2gray(template_image);
    template_binary_image = imbinarize(gray_template_image);
    size_of_template_binary_image = size(template_binary_image);

    resized_binary_image = imresize(binary_image,size_of_template_binary_image);
    pixels_in_common = sum(~resized_binary_image & ~template_binary_image,"all");
    pixels_in_template_image = sum(~template_binary_image,"all");
    number_of_pixels_in_cluster_binary_image = sum(~resized_binary_image,"all");
    pixels_in_cluster_but_not_template =number_of_pixels_in_cluster_binary_image - pixels_in_common;
    if i<5
        elipse_like_score(i) =( pixels_in_common - pixels_in_cluster_but_not_template) / pixels_in_template_image;
    elseif i==5
        circularity =( pixels_in_common - pixels_in_cluster_but_not_template) / pixels_in_template_image;
    end
end
[best_elipse_score,~] = max(elipse_like_score);



%delete(file_save_name)
% get_grades_for_nth_pass_of_clustering(dir_with_timestamps_and_rvals,dir_with_output,list_of_tetrodes,dir_to_save_grades_to,config,varying_z_scores(2),debug,relevant_grades,name_of_grades)


close all;
end