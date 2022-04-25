function DataStaff = derivePatch(DataStaff, coefficients)
% readHoracekData - Read all data associated with the Horacek BSPM studies.
%
% Syntax: [DataHoracek] = readHoracekData(dataDir)
%
% Inputs:
%    dataDir - A character vector or string scalar. The full file path to
%       the folder where the Horacek data is stored.
%
% Outputs:
%    DataHoracek - A scalar structure containing the following fields:
%       * recordings - A table of N recordings with two columns:
%          - BSPM - A cell of 
%          - Filename - A character vector. The annotated filename with
%              patient metadata.
%
% Example:
%    [DataHoracek] = getHoracekData('C:/path_to_folder');
%
% Other m-files required: none
% Subfunctions: none
% Files required: BalloonBSPMdata.mat, daltorso.fac, daltorso.pts,
%    fileNames.txt
% ------------------------------------------------------------------------

%------------- BEGIN CODE --------------

tic;

%% Setup.
% Number of files.
nSubjects = length(DataStaff);

% Change the order of columns to work with the new coefficients.
% Extract_beat_WB rows are V1-V6, I-III.
% Beat columns are I-II, V1-V6.
orderOfFields = [7, 8, 1, 2, 3, 4, 5, 6];

%% Main code.
for iSubject = 1 : nSubjects

    % Extract data related to this subject.
    thisData = DataStaff(iSubject);

    % Extract the 8-independent leads of the 12-lead ECG (I-II, V1-V6).
    thisLeads = thisData.signals.extract_beat_WB(orderOfFields, :)';

    % Derive the patch (nSamples x 2).
    thisDerivedLeads = thisLeads * coefficients';

    % Append to the struct.
    DataStaff(iSubject).signals.patch = thisDerivedLeads;

end

%% Output.
% Output run time.
t = toc;
disp([mfilename, ': ', num2str(t), ' seconds']);
end