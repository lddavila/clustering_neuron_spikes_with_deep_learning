A = floor(10*rand(6));

B = A';
A(:.6) = -sum(B(1:5,:))';