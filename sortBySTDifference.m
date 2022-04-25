function SortedLeadsTable = sortBySTDifference(bspmData, responderIdx, ...
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
% Output file constants.
OUTPUT_DIR = fullfile(pwd, 'output');
OUTPUT_FILENAME = [mfilename, '.mat'];
OUTPUT_FILEPATH = fullfile(OUTPUT_DIR, OUTPUT_FILENAME);

% Check if the output of this function already exists.
if isfolder(OUTPUT_DIR) && isfile(OUTPUT_FILEPATH)

    disp([mfilename, ': Using pre-saved data.']);
    SortedLeadsTable = importdata(OUTPUT_FILEPATH);
    return;

end

%% Main code.

% Number of nodes. The first three rows are ignored.
nNodes = size(bspmData{1}, 1) - 3;

% Number of possible lead combinations.
nCombinations = nNodes ^ 2;

% Indicies of responders alternate in pairs.
baselineIdx = responderIdx(1 : 2 : end);
inflationIdx = responderIdx(2 : 2 : end);

% Number of baseline and peak balloon inflation (PBI) pairs.
nPairs = length(baselineIdx);

% Preallocate.
cumulativeSTRank = zeros(nNodes);

% Sort every possible lead combination by the absolute ST segment changes
% between baseline and inflation pairs.
for iPair = 1 : nPairs

    % Extract the indicies for this pair.
    thisBaselineIdx = baselineIdx(iPair);
    thisInflationIdx = inflationIdx(iPair);

    % Extract the data for the pair.
    thisBaselineBSPM = cell2mat(bspmData(thisBaselineIdx));
    thisInflationBSPM = cell2mat(bspmData(thisInflationIdx));

    % Extract the beat annotations.
    beatAnnotationBaseline = thisBaselineBSPM(1, :);
    beatAnnotationInflation = thisInflationBSPM(1, :);

    % Remove the annotation row and lead I/II recordings.
    thisBaselineBSPM(1 : 3, :) = [];
    thisInflationBSPM(1 : 3, :) = [];

    % Get number of samples and leads.
    nSamplesBaseline = size(thisBaselineBSPM, 2);
    nSamplesInflation = size(thisInflationBSPM, 2);

    %% Locate the ST segments.
    % Find the J point for the baseline record.
    for iSample = 1 : nSamplesBaseline

        % First '3' annotation denotes the J-point.
        if beatAnnotationBaseline(iSample) == 3

            % Delay by jDelay samples to get the ST segment.
            stSampleNoBaseline = iSample + jDelay;
            break;

        end

    end

    % Fnd the J-point for the inflation record.
    for iSample = 1 : nSamplesInflation

        if beatAnnotationInflation(iSample) == 3

            % Delay by jDelay samples to get the ST segment.
            stSampleNoInflation = iSample + jDelay;
            break;

        end

    end

    %% Calculate every possible lead combination.
    % e.g. lead(i) = allLeads(j) - allLeads(k)
    % Preallocate cell array.
    allLeadsBaseline = cell(nNodes, 1);
    allLeadsInflation = cell(nNodes, 1);
    stSegmentBaseline = nan(nNodes);
    stSegmentInflation = nan(nNodes);

    % For each node (n=352), calculate all lead combinations (n=352).
    for iCombination = 1 : nNodes

        % Extract the node that forms the first electrode.
        thisNodeBaseline = thisBaselineBSPM(iCombination, :);
        thisNodeInflation = thisInflationBSPM(iCombination, :);

        % Preallocate all lead combinations.
        thisAllLeadsBaseline = nan(nNodes, nSamplesBaseline);
        thisAllLeadsInflation = nan(nNodes, nSamplesInflation);

        for iNode = 1 : nNodes

            % Create a bipolar lead by subtracting each node from the
            % current node.
            thisSubtractedNodeBaseline = thisBaselineBSPM(iNode, :);
            thisAllLeadsBaseline(iNode, :) = thisNodeBaseline - ...
                thisSubtractedNodeBaseline;

            % Perform the same for the inflation recording.
            thisSubtractedNodeInflation = thisInflationBSPM(iNode, :);
            thisAllLeadsInflation(iNode, :) = thisNodeInflation - ...
                thisSubtractedNodeInflation;

        end

        % Assign the output to the cell array.
        allLeadsBaseline{iCombination} = thisAllLeadsBaseline;
        allLeadsInflation{iCombination} = thisAllLeadsInflation;

        % Extract the ST segment amplitudes.
        thisSTSegmentBaseline = thisAllLeadsBaseline(:, stSampleNoBaseline);
        thisSTSegmentInflation = thisAllLeadsInflation(:, ...
            stSampleNoInflation);

        % Rows represent the primary node. Columns represent the ST segment
        % amplitude from the created lead.
        stSegmentBaseline(iCombination, :) = thisSTSegmentBaseline;
        stSegmentInflation(iCombination, :) = thisSTSegmentInflation;

    end

    %% Sort by ST segment amplitude changes for the current pair.
    % Difference in ST segment amplitude between baseline and inflation.
    stSegmentDifference = abs(stSegmentInflation - stSegmentBaseline);

    % Sort by the greatest absolute difference in the ST segment for this
    % pair.
    % Get the indicies of the sorted data. 1 is the highest ST difference.
    [~, thisSortedIdx] = sort(stSegmentDifference(:), 'descend');

    % Transpose the output vector to match the 352 x 352 matrix.
    thisSortedSTDifference = nan(nNodes);
    thisSortedSTDifference(thisSortedIdx) = 1 : nCombinations;

    % Add this to the cumulative rank.
    cumulativeSTRank = cumulativeSTRank + thisSortedSTDifference;

end

%% Sort by ST segment differences across the entire dataset.
% Get the indicies of the sorted data. 1 is the highest ST difference.
[~, sortedIdx] = sort(cumulativeSTRank(:), 'ascend');

% Transpose the output vector to match the 352 x 352 matrix.
sortedSTDifference = nan(nNodes);
sortedSTDifference(sortedIdx) = 1 : nCombinations;

% Preallocate sorted lead pairs.
sortedLeadsByST = nan(nCombinations, 2);

% Create an nCombinations x 2 matrix of the sorted node numbers.
for iCombination = 1 : nCombinations

    [positiveNode, negativeNode] = find(sortedSTDifference == iCombination);
    sortedLeadsByST(iCombination, :) = [positiveNode, negativeNode];

end

%% Remove duplicate leads.
duplicateFlag = false(nCombinations, 1);

for iCombination = 1 : nCombinations

    % Ignore if the current row has already been marked as a duplicate.
    if duplicateFlag(iCombination)
        
        continue;

    end

    % Extract the node numbers.
    positiveNode = sortedLeadsByST(iCombination, 1);
    negativeNode = sortedLeadsByST(iCombination, 2);

    % Find where this pattern exists.
    for jCombination = 1 : nCombinations

        % Extract the row that will be compared against.
        thisRow = sortedLeadsByST(jCombination, :);
        
        if thisRow(1) == negativeNode && thisRow(2) == positiveNode

            % Duplicate found.
            duplicateFlag(jCombination) = true;
            break;

        end

    end

end

% Delete duplicate rows.
sortedLeadsBySTTrimmed = sortedLeadsByST(~duplicateFlag, :);

%% Save output.
SortedLeadsTable = array2table(sortedLeadsBySTTrimmed, 'VariableNames', ...
    {'negativeNode', 'positiveNode'});

% Save the table to the output folder.
% Check if the folder exists.
if ~isfolder(OUTPUT_DIR)

    mkdir(OUTPUT_DIR);

end

% Save the file.
save(OUTPUT_FILEPATH, 'SortedLeadsTable');

% Output run time.
t = toc;
disp([mfilename, ': ', num2str(t), ' seconds']);
end
%------------- END OF CODE -------------
