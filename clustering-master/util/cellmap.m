function varargout = cellmap(varargin)
    varargout{1} = cellfun(varargin{:}, 'UniformOutput', false);
end