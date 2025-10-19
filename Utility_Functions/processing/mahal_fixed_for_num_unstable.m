function d = mahal_fixed_for_num_unstable(Y,X)
%MAHAL Mahalanobis distance.
%   D2 = MAHAL(Y,X) returns the Mahalanobis distance (in squared units) of
%   each observation (point) in Y from the sample data in X, i.e.,
%
%      D2(I) = (Y(I,:)-MU) * SIGMA^(-1) * (Y(I,:)-MU)',
%
%   where MU and SIGMA are the sample mean and covariance of the data in X.
%   Rows of Y and X correspond to observations, and columns to variables.  X
%   and Y must have the same number of columns, but can have different numbers
%   of rows.  X must have more rows than columns.
%
%   Example:  Generate some highly correlated bivariate data in X.  The
%   observations in Y with equal coordinate values are much closer to X as
%   defined by Mahalanobis distance, compared to the observations with opposite
%   coordinate values, even though they are all approximately equidistant from
%   the mean using Euclidean distance.
%
%      x = mvnrnd([0;0], [1 .9;.9 1], 100);
%      y = [1 1;1 -1;-1 1;-1 -1];
%      MahalDist = mahal(y,x)
%      sqEuclidDist = sum((y - repmat(mean(x),4,1)).^2, 2)
%      plot(x(:,1),x(:,2),'b.',y(:,1),y(:,2),'ro')
%
%   See also PDIST.

%   Copyright 1993-2007 The MathWorks, Inc. 

% Force error on numerical instability
warning('error', 'MATLAB:singularMatrix');
warning('error', 'MATLAB:nearlySingularMatrix');
warning('error', 'MATLAB:illConditionedMatrix');
%we turn these warnings into errors in case our attempts to avoid the
%nearly singular error fails 


[rx,cx] = size(X);
[ry,cy] = size(Y);

%we'll z-score normalize X and Y in order to hopefully avoid instability
m = mean(X,1);
s = std(X,0,1);

X = (X-m) ./s;
Y = (Y -m)./ s;

if cx ~= cy
   error(message('stats:mahal:InputSizeMismatch'));
end

if rx < cx
   error(message('stats:mahal:TooFewRows'));
end
if any(imag(X(:))) || any(imag(Y(:))) %originally this line had a "|" instead of "||"
   error(message('stats:mahal:NoComplex'));
end

m = mean(X,1);
M = m(ones(ry,1),:);
C = X - m(ones(rx,1),:);
[Q,R] = qr(C,0);



%OG LINEri = R'\(Y-M)';
%OG LINEd = sum(ri.*ri,1)'*(rx-1);

%ADDED LINES
rhs = (Y-M)';

if rcond(R') < 1e-12 %in case the z-score normalization is insufficient of an ill condtitioned r to avoid instability
     ri = lsqminnorm(R', rhs);   % or: pinv(R')*rhs
else
    ri = R'\rhs;
end
d = sum(ri.*ri,1)'*(rx-1);
end