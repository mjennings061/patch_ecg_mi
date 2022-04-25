function SortedSTETable = steMaxIdx(bspmData, indexOfResponder, sslNodes, ...
    jDelay)
% filterHoracekData - Filter horacek data by positive response or vessel.
%
% Syntax: [iResponder] = filterHoracekData(filenames, vessel);
%
% Inputs:
%    filenames - Cell vector of string scalars or character vectors. 
%       Contains the filenames for the horacek data e.g. {'1001_B_Y_M_LAD'}
%    Optional:
%    vessel - Character vector or string scalar. Single vessel to include
%       e.g. 'LAD'.
%
% Outputs:
%    iResponder - Numerical vector. Contains the indicies of
%       responders as filtered from filenames.
%
% Example:
%    [iResponder] = filterHoracekData(filenames, 'RCA');
%
% Other m-files required: none
% Subfunctions: none
% Files required: none
% ------------------------------------------------------------------------

%------------- BEGIN CODE --------------

tic;

%% Setup.
% Indicies for baseline and inflation recordings in responders.
baselineIdx = indexOfResponder(1 : 2 : end);
inflationIdx = indexOfResponder(2 : 2 : end);

% Extract bspm recordings.
baselineBspm = bspmData(baselineIdx);
inflationBspm = bspmData(inflationIdx);

% Preallocation. 
nPairs = numel(baselineBspm);
baselineSSL = cell(nPairs, 1);
inflationSSL = cell(nPairs, 1);
stDifferences = nan(nPairs, 1);

for iPair = 1 : nPairs

    % Extract BSPM data for this subject.
    thisBaselineBspm = baselineBspm{iPair};
    thisInflationBspm = inflationBspm{iPair};

    % Find the ST-segment for baseline.
    thisBaselineSTIdx = getJPointIdx(thisBaselineBspm) + jDelay;
    thisInflationSTIdx = getJPointIdx(thisInflationBspm) + jDelay;

    % Trim BSPMs to discard unwanted data.
    thisBaselineBspm = thisBaselineBspm(4 : end, :);
    thisInflationBspm = thisInflationBspm(4 : end, :);

    % Extract positive and negative node numbers.
    positiveNode = sslNodes(2);
    negativeNode = sslNodes(1);

    % Create the SSLs.
    thisBaselineSSL = thisBaselineBspm(positiveNode, :) - ...
        thisBaselineBspm(negativeNode, :);
    thisInflationSSL = thisInflationBspm(positiveNode, :) - ...
        thisInflationBspm(negativeNode, :);

    % ST amplitude for each SSL during baseline and inflation.
    baselineSTAmplitude = thisBaselineSSL(thisBaselineSTIdx);
    inflationSTAmplitude = thisInflationSSL(thisInflationSTIdx);

    % Calculate the ST difference between baseline and inflation.
    thisSTDifference = inflationSTAmplitude - baselineSTAmplitude;

    % Output variables.
    baselineSSL{iPair} = thisBaselineSSL;
    inflationSSL{iPair} = thisInflationSSL;
    stDifferences(iPair) = thisSTDifference;

end

% Sort pair by greatest ST difference.
[~, sortedSTIdx] = sort(stDifferences, 'descend');

% Map the highest ST differences to the indexOfResponder variable.
baselineIdxByST = baselineIdx(sortedSTIdx);
inflationIdxByST = inflationIdx(sortedSTIdx);

%% Output.
% Output table of highest baseline and inflation recordings.
SortedSTETable = table(baselineIdxByST, inflationIdxByST, baselineSSL, ...
    inflationSSL, 'VariableNames', {'BaselineIdx', 'InflationIdx', ...
    'BaselineSSL', 'InflationSSL'});

% Output run time.
t = toc;
disp([mfilename, ': ', num2str(t), ' seconds']);
end

function jPointIdx = getJPointIdx(bspmMatrix)
% Extract the J-point sample number from a BSPM.

% Number of samples.
nSamples = size(bspmMatrix, 2);

% Extract annotations.
annotations = bspmMatrix(1, :);

% Find the J-point.
for iSample = 1 : nSamples

    if annotations(iSample) == 3

        % J-point found.
        jPointIdx = iSample;
        break;

    end

end
end