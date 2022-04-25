function [trainFlag] = splitData(data, trainRatio)
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
 
% Number of total files.
nSubjects = size(data, 1);

% Partition data indicies.
c = cvpartition(nSubjects, 'HoldOut', trainRatio);
idx = c.test';

% Output run time.
t = toc;
disp([mfilename, ': ', num2str(t), ' seconds']);
end