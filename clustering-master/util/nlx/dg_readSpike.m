function [TS, Samples, Hdr] = dg_readSpike(filename, varargin)
% Does not read return values that are not used.  Note that this is based
% purely on the number of return values, so values whose return is
% suppressed by using '~' *do* still get read.  Uses the v3 unix versions
% for Linux and Mac, and the v4.11 versions for Windows.  If filename has
% '.dat' extension, assumes it's a tetrode file.
% OUTPUTS
%   TS: timestamps
%   Samples: spike waveform samples formatted as a 32xMxN matrix of data
%       points, where M is the number of subchannels (wires) in the spike
%       file (NTT M = 4, NST M = 2, NSE M = 1). These values are in AD
%       counts.
%	Hdr: text header (maximum length 16 kB)
% OPTIONS
%   'header' - reads only header, returns empty for TS and Samples
%   'mode', modenum, modearg - invokes the Neuralynx "Extraction Mode"
%       specified by <modenum> (default is 1).  In keeping with the new
%       convention of Nlx library v5.0.1, the first record is record 1,
%       whereas in releases through v4.1.3 it was record 0.
%         1. Extract All
%         2. Extract Record Index Range
%         3. Extract Record Index List
%         4. Extract Timestamp Range
%         5. Extract Timestamp List
% NOTES
% Tested to return identical values from .ntt file on WinXP and Mac OS X
% 10.5.8.  On Gentoo Linux, <TS> and <Samples> are identical but certain
% special characters are missing in the header strings (notably the Greek
% letter mu in the "-DspFilterDelay_µs" variable name).

%$Rev: 155 $
%$Date: 2012-08-07 20:42:07 -0400 (Tue, 07 Aug 2012) $
%$Author: dgibson $

TS = [];
Samples = [];
if nargout >= 2
    selectary = [1, 0, 0, 0, 1];
else
    selectary = [1, 0, 0, 0, 0];
end
if nargout >= 3
    readheader = 1;
else
    readheader = 0;
end
headeronly = false;
modenum = 1;
modearg = [];
argnum = 1;
while argnum <= length(varargin)
    switch varargin{argnum}
        case 'header'
            headeronly = true;
        case 'mode'
            argnum = argnum + 1;
            modenum = varargin{argnum};
            argnum = argnum + 1;
            modearg = varargin{argnum};
        otherwise
            error('dg_readSpike:badoption', ...
                ['The option "' varargin{argnum} '" is not recognized.'] );
    end
    argnum = argnum + 1;
end
[p, n, ext] = fileparts(filename); %#ok<ASGLU>
if strcmpi(ext, '.dat')
    warning('dg_readSpike:ext', ...
        'This Nlx function requires .ncs extension; making temporary copy of %s.', ...
        filename );
    tempfn = [tempname '.ntt'];
    while exist(tempfn) %#ok<EXIST>
        tempfn = [tempname '.ntt'];
    end
    dg_copyfile(filename, tempfn);
    file2read = tempfn;
else
    file2read = filename;
end

if ispc
    if ismember(modenum, [2 3])
        % v4.1.1 uses 0 to denote the first record
        modearg = modearg - 1;
    end
    if headeronly
        Hdr = Nlx2MatSpike(file2read, [0, 0, 0, 0, 0], 1, 1);
    else
        if nargout > 2
            [TS, Samples, Hdr] = Nlx2MatSpike(file2read, selectary, ...
                readheader, modenum, modearg);
        elseif nargout == 2
            [TS, Samples] = Nlx2MatSpike(file2read, selectary, ...
                readheader, modenum, modearg);
        else
            % nargout must be 1
            TS = Nlx2MatSpike(file2read, selectary, ...
                readheader, modenum, modearg);
        end
    end
elseif ismac || isunix
    if ismember(modenum, [2 3])
        % The unix version uses 0 to denote the first record
        modearg = modearg - 1;
    end
    if headeronly
        Hdr = Nlx2MatSpike_v3(file2read, [0, 0, 0, 0, 0], 1, 1);
    else
        if nargout > 2
            [TS, Samples, Hdr] = Nlx2MatSpike_v3(file2read, selectary, ...
                readheader, modenum, modearg);
        elseif nargout == 2
            [TS, Samples] = Nlx2MatSpike_v3(file2read, selectary, ...
                readheader, modenum, modearg);
        else
            % nargout must be 1
            TS = Nlx2MatSpike_v3(file2read, selectary, ...
                readheader, modenum, modearg);
        end
    end
    if strcmpi(ext, '.dat')
        dg_deletefile(tempfn);
    end
else
    error('dg_readSpike:arch', ...
        'Unrecognized computer platform');
end
if exist('Hdr', 'var') && ...
        (isempty(Hdr{end}) || ~isempty(regexp(Hdr{end}, '^\s*$', 'once' )))
    Hdr(end) = [];
end

