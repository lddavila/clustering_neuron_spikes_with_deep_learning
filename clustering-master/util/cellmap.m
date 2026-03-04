%edited by Luis David Davila and Alexander Friedman
function varargout = cellmap(varargin)
    varargout{1} = cellfun(varargin{:}, 'UniformOutput', false);
end