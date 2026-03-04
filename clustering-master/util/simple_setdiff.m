%edited by Luis David Davila and Alexander Friedman
function the_C = simple_setdiff(the_A, the_B)
% SIMPLE_SETDIFF Set difference of two sets of positive integers (much faster than built-in setdiff)
% C = simple_setdiff(A,B)
% C = A \ B = { things in A that are not in B }
    
    if isempty(the_A)
        the_C = [];
        return;
    elseif isempty(the_B)
        the_C = the_A;
        return;
    else
        bits = false(1, max(max(the_A), max(the_B)));
        bits(the_A) = true;
        bits(the_B) = false;
        the_C = the_A(bits(the_A));
    end
end