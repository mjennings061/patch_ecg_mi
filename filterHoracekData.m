function [indexOfResponder] = filterHoracekData(filenames, vessel)
% filterHoracekData - Filter horacek data by positive response or vessel.
%
% Syntax: [indexOfResponder] = filterHoracekData(filenames, vessel);
%
% Inputs:
%    filenames - Cell vector of string scalars or character vectors. 
%       Contains the filenames for the horacek data e.g. {'1001_B_Y_M_LAD'}
%    vessel - Character vector or string scalar. Single vessel to include
%       e.g. 'LAD' or 'all'.
%
% Outputs:
%    indexOfResponder - Numerical vector. Contains the indicies of
%       responders as filtered from filenames.
%
% Example:
%    [indexOfResponder] = filterHoracekData(filenames, 'RCA');
%
% Other m-files required: none
% Subfunctions: none
% Files required: none
% ------------------------------------------------------------------------

%------------- BEGIN CODE --------------

tic;

%% Setup.
% Check number of input arguments.
MIN_ARGS = 2;
MAX_ARGS = 2;
narginchk(MIN_ARGS, MAX_ARGS);

%% Main Code.
% Preallocation.
nFiles = length(filenames);
responderNames = cell(nFiles, 1);

for iFile = 1 : nFiles - 1

    % Get filenames.
    thisFilename = filenames(iFile);
    nextFilename = filenames(iFile + 1);

    % Find a baseline/peak inflation pair.
    if contains(thisFilename, '_B_Y_') && contains(nextFilename, '_P_')

        % All responding patients included for vessel == 'all'.
        if strcmp(vessel, 'all')

            % A baseline/peak-inflation pair found. Save info.
            responderNames(iFile) = thisFilename;
            responderNames(iFile + 1) = nextFilename;

        else

            if strcmp(thisFilename, vessel)

                % Specific vessel required.
                responderNames(iFile) = thisFilename;
                responderNames(iFile + 1) = nextFilename;

            end

        end

    end

end


% Find empty cells.
invalidFlag = cellfun(@(x) isempty(x), responderNames);

% Extract indicies for responders.
responderIdx = find(~invalidFlag);

%% Output.
indexOfResponder = responderIdx;

% Output run time.
t = toc;
disp([mfilename, ': ', num2str(t), ' seconds']);
end