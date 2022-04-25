function ShortLeadStatsTable = calculateLeadStats(bspmData, ...
    indexOfResponder, sslNodes, jDelay)
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

% Number of leads to calculate stats on.
N_LEADS_OUTPUT = 16;

% Setup.
nSubjects = numel(indexOfResponder);

% Get the indicies of baseline and inflation data.
baselineIdx = 1 : 2 : nSubjects;
inflationIdx = 2 : 2 : nSubjects;

% Extract the data for each.
baselineBspm = bspmData(indexOfResponder(baselineIdx));
inflationBspm = bspmData(indexOfResponder(inflationIdx));

% Number of baseline/inflation pairs.
nPairs = numel(baselineBspm);

% Preallocation.
deltaST = nan(nPairs, N_LEADS_OUTPUT);

% Loop through all responding subjects.
for iPair = 1 : nPairs

    % Extract this subject data.
    thisBaselineBspm = cell2mat(baselineBspm(iPair));
    thisInflationBspm = cell2mat(inflationBspm(iPair));

    % Extract annotations.
    baselineAnnotations = thisBaselineBspm(1, :);
    inflationAnnotations = thisInflationBspm(1, :);

    % Remove lead I, II, and annotations.
    thisBaselineBspm(1 : 3, :) = [];
    thisInflationBspm(1 : 3, :) = [];

    % Length of each recording.
    nSamplesBaseline = size(thisBaselineBspm, 2);
    nSamplesInflation = size(thisInflationBspm, 2);

    % Find the ST segment for baseline.
    for iSample = 1 : nSamplesBaseline

        if baselineAnnotations(iSample) == 3

            % Delay to get the ST-segment.
            stIdxBaseline = iSample + jDelay;
            break;

        end

    end

    % Find the ST segment for inflation.
    for iSample = 1 : nSamplesInflation

        if inflationAnnotations(iSample) == 3

            % Delay to get the ST-segment.
            stIdxInflation = iSample + jDelay;
            break;

        end

    end

    % Extract the twelve lead ECG and short spaced lead.
    BaselineLeadTable = getTwelveLeadSSL(thisBaselineBspm, sslNodes);
    InflationLeadTable = getTwelveLeadSSL(thisInflationBspm, sslNodes);

    % Log the amplitude on the ST-segment.
    baselineST = table2array(BaselineLeadTable(stIdxBaseline, :));
    inflationST = table2array(InflationLeadTable(stIdxInflation, :));
    thisDeltaST = abs(inflationST - baselineST);

    % Save to the output variable.
    deltaST(iPair, :) = thisDeltaST;

end

% Calculate statistics for ST changes in each lead.
deltaSTMean = mean(deltaST);
deltaSTMedian = median(deltaST);
deltaSTStd = std(deltaST);
deltaSTCoVar = deltaSTStd ./ deltaSTMean;

% Append stats to one array.
deltaSTStats = [deltaSTMean; deltaSTMedian; deltaSTStd; deltaSTCoVar]';

% Assign the deltaST and statistics calculations to a table.
deltaSTCell = num2cell(deltaST, 1)';
ShortLeadStatsTable = [deltaSTCell, array2table(deltaSTStats)];

% Get the rowNames and variableNames.
ShortLeadStatsTable.Properties.VariableNames = {'DeltaST', 'Mean', ...
    'Median', 'STD', 'CoVar'};
ShortLeadStatsTable.Properties.RowNames = ...
    BaselineLeadTable.Properties.VariableNames;

% Output run time.
t = toc;
disp([mfilename, ': ', num2str(t), ' seconds']);
end

function LeadTable = getTwelveLeadSSL(bspmData, sslNodes)
% Extract the twelve lead ECG, short spaced lead, and Horacek
% vessel-specific leads from a Horacek BSPM.

% Calculate the Mason-Likar nodes.
rightArm = (bspmData(60, :) + bspmData(101, :)) / 2;
leftArm = (bspmData(50, :) + bspmData(90, :)) / 2;
leftLeg = (3 * bspmData(343, :) + 2 * bspmData(344, :)) / 5;

% Calculate ML limb leads.
leadI = leftArm - rightArm;
leadII = leftLeg - rightArm;
leadIII = leftLeg - leftArm;

% Calculate unipolar augmented leads.
leadAVR = -(leadI + leadII) / 2;
leadAVL = (leadI - leadIII) / 2;
leadAVF = (leadII + leadIII) / 2;

% Unipolar chest leads.
leadV1 = bspmData(169, :);
leadV2 = bspmData(171, :);
leadV3 = (bspmData(192, :) + bspmData(193, :)) / 2;
leadV4 = bspmData(216, :);
leadV5 = (bspmData(217, :) + 2 * bspmData(218, :)) / 3;
leadV6 = bspmData(219, :);

% Vessel-specific leads.
leadLAD = bspmData(174, :) - bspmData(221, :);
leadLCX = bspmData(221, :) - bspmData(150, :);
leadRCA = bspmData(342, :) - bspmData(129, :);

% Short-spaced lead.
positiveNode = sslNodes(2);
negativeNode = sslNodes(1);
leadSSL = bspmData(positiveNode, :) - bspmData(negativeNode, :);

% Combine all leads into one matrix.
allLeads = [leadI; leadII; leadIII; leadAVR; leadAVL; leadAVF; ...
    leadV1; leadV2; leadV3; leadV4; leadV5; leadV6; leadLAD; leadLCX; ...
    leadRCA; leadSSL]';

% Output the array to the table.
LeadTable = array2table(allLeads);
LeadTable.Properties.VariableNames = {'I', 'II', 'III', 'aVR', 'aVL', ...
    'aVF', 'V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'vslLAD', 'vslLCX', ...
    'vslRCA', 'SSL'};

end