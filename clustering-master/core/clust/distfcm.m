%this file has been edited by Luis D. Davila and Alexander Friedman 
function output = distfcm(the_center, the_data)
%DISTFCM Distance measure in fuzzy c-mean clustering.
%	OUT = DISTFCM(CENTER, DATA) calculates the Euclidean distance
%	between each row in CENTER and each row in DATA, and returns a
%	distance matrix OUT of size M by N, where M and N are row
%	dimensions of CENTER and DATA, respectively, and OUT(I, J) is
%	the distance between CENTER(I,:) and DATA(J,:).
%
%       See also FCMDEMO, INITFCM, IRISFCM, STEPFCM, and FCM.

%	Roger Jang, 11-22-94, 6-27-95.
%       Copyright 1994-2002 The MathWorks, Inc. 
%       $Revision: 1.13 $  $Date: 2002/04/14 22:20:29 $

output = zeros(size(the_center, 1), size(the_data, 1));

% fill the output matrix

if size(the_center, 2) > 1,
    for k = 1:size(the_center, 1),
	output(k, :) = sqrt(sum(((the_data-ones(size(the_data, 1), 1)*the_center(k, :)).^2)'));
    end
else	% 1-D data
    for k = 1:size(the_center, 1),
	output(k, :) = abs(the_center(k)-the_data)';
    end
end
