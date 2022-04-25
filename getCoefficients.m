function coefficients = getCoefficients(DataTable, nodes)
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
% Constants.
N_PREDICTOR_LEADS = 8;

% Nodes must be adjusted by three, to account for the three rows of the
% BSPM used for annotations, lead I and lead II.
nodes = nodes + 3;

% Get indicies.
idx = DataTable.trainFlag;

% Extract the data.
bspmData = DataTable.BSPM(idx);

%% Main code. 
% Length of each recording.
nSubjects = length(bspmData);

% Preallocate.
pooledPredictors = [];
pooledTarget = [];

% Pool all samples.
for iSubject = 1 : nSubjects

    % Get the twelve lead ECG.
    thisBspm = bspmData{iSubject};
    thisTwelveLead = extractTwelveLeadBSPM(thisBspm);

    % Calculate the target lead.
    thisTargetLead = thisBspm(nodes(2), :) - thisBspm(nodes(1), :);

    % Number of samples.
    nSamples = size(thisBspm, 2);

    % Add to the pooled variables.
    pooledPredictors(:, end + 1 : end + nSamples) = thisTwelveLead;
    pooledTarget(:, end + 1 : end + nSamples) = thisTargetLead;

end

% Derive coefficients from the pooled data.
coefficients = pooledTarget / pooledPredictors;

% Output run time.
t = toc;
disp([mfilename, ': ', num2str(t), ' seconds']);
end
%------------- END OF CODE -------------