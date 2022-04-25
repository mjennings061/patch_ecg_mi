function StaffStatsTable = getStaffStats(DataStaff)
% StaffStatsTable - Get classification performance stats from the STAFF
% dataset.
%------------- BEGIN CODE --------------

%% Setup.
% Extract vessel.
VESSELS = {'All', 'LAD', 'circ', 'RCA'};
vesselsStaff = {DataStaff.artery}';

% Preallocation.
nVessels = numel(VESSELS);
nSubjects = length(DataStaff);

for iVessel = 1 : nVessels

    % Current vessel.
    thisVessel = VESSELS{iVessel};

    % Use all recordings when 'all' is specified.
    if strcmp(thisVessel, 'All')

        thisVesselFlag = true(nSubjects, 1);

    else

        % Get indicies for cells matching the current vessel.
        thisVesselFlag = cellfun(@(x) contains(x, {'Baseline', thisVessel}), ...
            vesselsStaff);

    end

    % Get the stats for this vessel combination.
    ThisStatsTable = getStats(DataStaff(thisVesselFlag));

    % Create column for vessel annotation.
    thisVesselColumn = repmat({thisVessel}, height(ThisStatsTable), 1);

    % Append the artery used to filter the data.
    ThisStatsTable.artery = thisVesselColumn;

    % Append to StaffStatsTable.
    if exist('StaffStatsTable', 'var')

        StaffStatsTable = [StaffStatsTable; ThisStatsTable]; %#ok

    else

        StaffStatsTable = ThisStatsTable;

    end

end

% Output run time.
t = toc;
disp([mfilename, ': ', num2str(t), ' seconds']);
end

%% Subfunctions.
function StatsTable = getStats(DataStaff)
% Get stats from the staff data.

ROW_NAMES = {'12-Lead', '12-Lead Depression', 'Patch 050uV', 'Patch 100uv', ...
    'Patch_150uV', 'Patch_200uV', 'Patch_250uV', 'Patch_300uV'};

% Setup and extract annotations.
annotations = [DataStaff.Lead12; DataStaff.Lead12Dep; DataStaff.patch_50uV; ...
    DataStaff.patch_100uV; DataStaff.patch_150uV; DataStaff.patch_200uV; ...
    DataStaff.patch_250uV; DataStaff.patch_300uV]';

% Extract target variable.
target = [DataStaff.ann]';

% Number of tests.
nTests = size(annotations, 2);

% Preallocate.
sens = nan(1, nTests);
spec = nan(1, nTests);
ppv = nan(1, nTests);
npv = nan(1, nTests);
f1 = nan(1, nTests);

% Calculate true positives etc.
for iTest = 1 : nTests

    % Get the predictions to test against.
    thisPrediction = annotations(:, iTest);
    
    % Calculate TP and TN.
    adder = target + thisPrediction;
    true_positive = length(find(adder == 2));
    true_negative = length(find(adder == 0));

    % Calculate FP and FN
    subtr = target - thisPrediction;
    false_positive = length(find(subtr == -1));
    false_negative = length(find(subtr == 1));

    % Calculate sens, spec, ppv, npv, f1 score.
    sens(iTest) = true_positive /(true_positive + false_negative);
    spec(iTest) = true_negative / (true_negative + false_positive);
    ppv(iTest) = true_positive / (true_positive + false_positive);
    npv(iTest) = true_negative / (false_negative + true_negative);
    f1(iTest) = true_positive / (true_positive + 0.5 * ...
        (false_positive + false_negative));

end

% Pre-assign variable names for the table.
variableNames = {'Lead System', 'Sensitivity', 'Specificity', 'PPV', ...
    'NPV', 'F1 Score'};

% Create a blank table with column labels.
StatsTable = table(ROW_NAMES', sens', spec', ppv', npv', f1', ...
    'VariableNames', variableNames);

end
%------------- END OF CODE -------------