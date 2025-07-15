function [table_of_clusters] = add_letter_grade_based_on_nn(table_of_clusters)
have_pred_cols =check_for_required_cols(table_of_clusters,["mean_wave_pred","grades_pred"],"add_letter_grade_based_on_nn.mat","",1);
if ~have_pred_cols
    return
end
letter_grades = repelem("",size(table_of_clusters,1),1);
for i=1:size(table_of_clusters,1)
    wave_pred = table_of_clusters{i,"mean_wave_pred"};
    grades_pred = table_of_clusters{i,"grades_pred"};
    if grades_pred==2 && wave_pred==2
        letter_grades(i) = "A+";
    elseif grades_pred ==2 && wave_pred ==1
        letter_grades(i) = "A";
    elseif grades_pred ==2 && wave_pred == 0
        letter_grades(i) = "A-";
    elseif grades_pred==1 && wave_pred==2
        letter_grades(i) = "B+";
    elseif grades_pred==1 && wave_pred==1
        letter_grades(i) = "B";
    elseif grades_pred==1 && wave_pred==0
        letter_grades(i) = "B-";
    elseif grades_pred==0 && wave_pred==2
        letter_grades(i) = "C+";
    elseif grades_pred ==0 && wave_pred==1
        letter_grades(i) = "C";
    elseif grades_pred== 0 && wave_pred==0
        letter_grades(i) = "C-";
    end
end
table_of_clusters.letter_grades = letter_grades;
end