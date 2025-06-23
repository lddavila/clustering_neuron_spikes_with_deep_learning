function dg_cutClust2Nlx(clustfile, nlxfile)
%dg_cutClust2Nlx(clustfile, nlxfile)
% Creates an appropriately formatted Neuralynx file to represent the data
% in <clustfile>.  Uses the CellNumbers field to store cluster numbers.  If
% there are 32 waveform data points or fewer, then it is stored as .NSE; 33
% to 64 points, .NTS; 65 or more, .NTT.  Converts timestamps from seconds
% to microseconds.  Scales and converts waveform data to the integer range
% -32769:32768, setting ADBitVolts appropriately, based on the assumption
% that the original data were in microvolts.
%WARNING: This function will heedlessly overwrite any file that may already
%   exist at <nlxfile>.
%INPUTS
% clustfile: absolute or relative path to Multiple Cut Cluster file, as
%   defined in lfp_add.
% nlxfile: absolute or relative output path to Neuralynx format spike file.

%$Rev: 161 $
%$Date: 2012-11-14 17:33:14 -0500 (Wed, 14 Nov 2012) $
%$Author: dgibson $

S = load(clustfile);
fields = fieldnames(S);
% <clustdata> is in spikes X [TS clustnum samples] format:
clustdata = S.(fields{1});
numpts = size(clustdata,2) - 2;
if numpts <= 32
    datapts = zeros(32, 1, size(clustdata,1));
    if numpts > 0
        datapts(1:numpts, 1, :) = clustdata(:, 3:end);
    end
elseif numpts > 32 && numpts <=64
    datapts = clustdata(:, 3:end);
    if numpts < 64
        datapts = [datapts zeros(size(datapts,1), 64 - numpts)];
    end
    datapts = reshape(datapts', 32, 2, []);
else
    datapts = clustdata(:, 3:end);
    if numpts < 128
        datapts = [datapts zeros(size(datapts,1), 128 - numpts)];
    elseif numpts > 128
        datapts(:, 129:end) = [];
    end
    datapts = reshape(datapts', 32, 4, []);
end
% datapts is now in (samples X wires X spikes) format
maxv = max(datapts(:));
minv = min(datapts(:));
posscale = maxv/32768;
negscale = -minv/32769;
adbitmicrovolts = min(posscale, negscale);
adbitvolts = adbitmicrovolts / 1000000;
switch size(datapts,2)
    case 1
        bitvoltstr = sprintf('-ADBitVolts %12.10f ', adbitvolts);
    case 2
        bitvoltstr = sprintf('-ADBitVolts %12.10f %12.10f ', ...
            adbitvolts, adbitvolts);
    case 4
        bitvoltstr = sprintf('-ADBitVolts %12.10f %12.10f %12.10f %12.10f ', ...
            adbitvolts, adbitvolts, adbitvolts, adbitvolts);
end
Hdr = {
    '######## Neuralynx Data File Header'
    sprintf('## File Name: %s ', clustfile)
    sprintf('## Time Opened: (m/d/y): %s  At Time: %s ', ...
    datestr(now, 2), datestr(now, 2))
    '## Converted by dg_cutClust2Nlx '
    ''
    '-ADMaxValue 32767 '
    bitvoltstr
    ''
    sprintf('-NumADChannels %d ', size(datapts,2));
    ' '
    };
dg_writeSpike( nlxfile, round(1e6 * reshape(clustdata(:,1), 1, [])), ...
    round(datapts/adbitmicrovolts), Hdr, 'cellnums', ...
    reshape(clustdata(:,2), 1, []) );

