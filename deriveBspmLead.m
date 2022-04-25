function [DerivedLeadStatsTable, DerivedLeadTable] = deriveBspmLead(DataKornreich, ...
    coefficients, patchNodes)
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
testBspmKornreich = DataKornreich.BSPM(~DataKornreich.trainFlag);
nSubjectsTest = length(testBspmKornreich);

% Preallocate.
targetLead = cell(nSubjectsTest, 1);
derivedLead = cell(nSubjectsTest, 1);
rmse = nan(nSubjectsTest, 2);
correlation = nan(nSubjectsTest, 2);

%% Main code.
% Derive patch for each subject.
for iSubject = 1 : nSubjectsTest

    % Get BSPM.
    thisBspm = testBspmKornreich{iSubject};

    % Extract 12-lead ECG.
    thisTwelveLead = extractTwelveLeadBSPM(thisBspm);

    % Extract target leads. Add three to rows to compensate for
    % annotations.
    thisTargetLead = thisBspm(patchNodes(:, 2) + 3, :) - ...
        thisBspm(patchNodes(:, 1) + 3, :);

    % Derive patch.
    thisDerivedLead = coefficients * thisTwelveLead;

    % Get RMSE for the derived lead.
    thisRmse = sqrt(mean(thisTargetLead - thisDerivedLead, 2) .^ 2);

    % Get CC for SSL.
    c = corrcoef(thisTargetLead(1, :), thisDerivedLead(1, :));
    thisCorrelationSSL = c(1, 2);

    % Get CC for orthogonal lead.
    c = corrcoef(thisTargetLead(2, :), thisDerivedLead(2, :));
    thisCorrelationOrth = c(1, 2);

    % Output variables.
    targetLead{iSubject} = thisTargetLead;
    derivedLead{iSubject} = thisDerivedLead;
    rmse(iSubject, :) = thisRmse;
    correlation(iSubject, :) = [thisCorrelationSSL, thisCorrelationOrth];

end

% Calculate median CC and RMSE.
medianCC = median(correlation);
medianRMSE = median(rmse);

%% Output.
% Output to a table for all subjects.
DerivedLeadTable = table(targetLead, derivedLead, rmse, correlation);

% Output to a stats table.
derivedLeadRowNames = {'I', 'II', 'V1', 'V2', 'V3', 'V4', 'V5', 'V6', ...
    'Correlation Coefficient', 'Root-Mean Square Error'};
DerivedLeadStatsTable = array2table([coefficients'; medianCC; medianRMSE], ...
    'VariableNames', {'SSL_ST', 'SSL_Orth'});
DerivedLeadStatsTable.Properties.RowNames = derivedLeadRowNames;

% Output run time.
t = toc;
disp([mfilename, ': ', num2str(t), ' seconds']);
end
%------------- END OF CODE -------------