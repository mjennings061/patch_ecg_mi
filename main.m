function main(testFlag)
% runPatchDerivation - A script to execute the Jennings et al 2022
% derivation of a short-spaced lead patch suitable for ST-segment
% monitoring. Sections are split as follows:
%     Lead selection - Using the Horacek et al datasets to select a lead
%         suited for ST-segment monitoring.
%     Lead derivation - The generation of coefficients to derive the
%         short-spaced lead patch from the 12-lead ECG using linear
%         interpolation.
%     Classification performance - The evaluation of the capability of the
%         introduced patch system to detect ECG changes associated with
%         myocardial infarction.
%
% ----------------------------------------------------------------------- %

%% Setup.
MIN_ARGS = 0;
MAX_ARGS = 1;
narginchk(MIN_ARGS, MAX_ARGS);

if nargin == MIN_ARGS
    
    % Initialise testFlag if not supplied.
    testFlag = false;

    % Clean up base workspace.
    evalin('base', 'clear')
    evalin('base', 'close all')
    clc
    
end

% Download datasets.
if exist('data.zip', 'file') && exist('datasets', 'dir')

    disp('Using cached data.')

else

    disp('Downloading and unzipping data files.');
    websave('data.zip', ['https://drive.google.com/file/d/', ...
        '1HX54lNvcYCBlTy5LD4JxihzvyxTFZqP5/view?usp=sharing']);

    % Unzip into data directory.
    unzip('datasets.zip');

end

%% Patch-based lead selection.
% Maximum distance between electrodes in millimeters.
MAX_ELECTRODE_DISTANCE = 100;

% Extract the Horacek data and annotations.
horacekDir = fullfile(pwd, 'datasets', 'Horacek');
DataHoracek = readHoracekData(horacekDir);

% Filter Horacek data to return responders only. 
indexOfResponder = filterHoracekData(DataHoracek.DataTable.fileName, 'all');

% Rank each lead combination by greatest overall ST changes.
SortedLeadsTable = sortBySTDifference(DataHoracek.DataTable.bspmData, ...
    indexOfResponder, DataHoracek.J_DELAY);

% Filter the leads to return only those spaced less than 100 mm apart.
ShortLeadsTable = electrodeDistanceFilter(SortedLeadsTable, ...
    DataHoracek.points, DataHoracek.face, MAX_ELECTRODE_DISTANCE);

% Get the electrode locations for the chosen short spaced lead (SSL).
chosenSSL = table2array(ShortLeadsTable(1, :));

% Calculate performance metrics for the chosen short lead.
ShortLeadStatsTable = calculateLeadStats(DataHoracek.DataTable.bspmData, ...
    indexOfResponder, chosenSSL, DataHoracek.J_DELAY);

% Plot a BSPM for the SSL and spatially orthogonal lead.
ORTH_SSL = [212, 234];
plotBSPM(DataHoracek, indexOfResponder, chosenSSL, ORTH_SSL);

% Find the most ST-elevated subject.
maxSTESubjectIdx = steMaxIdx(DataHoracek.DataTable.bspmData, ...
    indexOfResponder, chosenSSL, DataHoracek.J_DELAY);

% Plot SSL for the most ST-elevated subject.
patchNodes = [chosenSSL; ORTH_SSL];
plotSSLDifference(DataHoracek, maxSTESubjectIdx(2, :), patchNodes);

%% Calculate regression coefficients of patch from the 12-lead ECG.
% Extract data from the Kornreich dataset.
kornreichDir = fullfile(pwd, 'datasets', 'Kornreich');
DataKornreich = readKornreichData(kornreichDir);

% Split the recordings into 80% training, 20% test.
TEST_RATIO = 0.2;
nSubjectsKornreich = size(DataKornreich, 1);
rng('default') % For reproducibility.
PartitionObj = cvpartition(nSubjectsKornreich, 'HoldOut', TEST_RATIO);

% Append indicies for training to the data table.
trainFlag = training(PartitionObj);
DataKornreich.trainFlag = trainFlag;

% Calculate regression coefficients from the training data.
sslCoefficients = getCoefficients(DataKornreich, patchNodes(1, :));
orthCoefficients = getCoefficients(DataKornreich, patchNodes(2, :));
coefficients = [sslCoefficients; orthCoefficients];

% Derive the patch using generated coefficients.
[DerivedLeadStatsTable, DerivedLeadTable] = deriveBspmLead(DataKornreich, ...
    coefficients, patchNodes); %#ok

%% Classification performance of the patch.
% Import the staff median beat data.
dataDir = fullfile(pwd, 'datasets', 'STAFF');

% Get matlab data files.
DataStaff = readStaffData(dataDir);

% Derive patch.
DataStaff = derivePatch(DataStaff, coefficients);

% Classify STEMI on patch and 12-lead ECG.
DataStaff = miClassifier(DataStaff);

% Get statistics based on artery of occlusion.
StaffStatsTable = getStaffStats(DataStaff);

%% Exit Script.
% Display result tables.
disp('Comparison of ST segment amplitude differences between lead systems.');
disp(ShortLeadStatsTable);
disp('Derivation performance of the patch based lead system.');
disp(DerivedLeadStatsTable);
disp('MI classification performance of the 12-lead and patch lead systems.')
disp(StaffStatsTable);

% Output workspace.
if ~testFlag
    
    exportAllToBaseWorkspace();
    
end
end