function C = simple_setdiff(A, B)
% SIMPLE_SETDIFF Set difference of two sets of positive integers (much faster than built-in setdiff)
% C = simple_setdiff(A,B)
% C = A \ B = { things in A that are not in B }
    
    if isempty(A)
        C = [];
        return;
    elseif isempty(B)
        C = A;
        return;
    else
        bits = false(1, max(max(A), max(B)));
        bits(A) = true;
        bits(B) = false;
        C = A(bits(A));
    end
end