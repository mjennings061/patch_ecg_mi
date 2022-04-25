function [DataHoracek] = readHoracekData(dataDir)
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
% Check number of input arguments.
MIN_ARGS = 1;
MAX_ARGS = 1;
narginchk(MIN_ARGS, MAX_ARGS);

% Output file constants.
OUTPUT_DIR = fullfile(pwd, 'output');
OUTPUT_FILENAME = [mfilename, '.mat'];
OUTPUT_FILEPATH = fullfile(OUTPUT_DIR, OUTPUT_FILENAME);

% Check if the output of this function already exists.
if isfolder(OUTPUT_DIR) && isfile(OUTPUT_FILEPATH)

    disp([mfilename, ': Using pre-saved data.']);
    DataHoracek = importdata(OUTPUT_FILEPATH);
    return;

end

%% Main code.
bspmData = importdata(fullfile(dataDir, "BalloonBSPMdata.mat"))';
fileNames = importdata(fullfile(dataDir, "fileNames.txt"));

% 3D vertices and edges.
points = importdata(fullfile(dataDir, "daltorso.pts"));
face = importdata(fullfile(dataDir, "daltorso.fac"));

% Sampling frequency.
FS = 500;

% Delay period between J-point and ST-segment.
J_DELAY = 40e-3 / (1 / FS);

% Check if baseline recording.
subjectId = cellfun(@(x) x(1 : 4), fileNames, 'UniformOutput', false);
isResponder = contains(fileNames, '_Y_');
isInflation = contains(fileNames, '_P_');
isFemale = contains(fileNames, '_F_');
vessel = cellfun(@(x) x(end - 2 : end), fileNames, 'UniformOutput', false);

%% Output.
% Combine BSPM data and filenames/annotations into a table.
DataTable = table(bspmData, fileNames, subjectId, isResponder, ...
    isInflation, isFemale, vessel, 'VariableNames', {'bspmData', 'fileName', ...
    'subjectId', 'isResponder', 'isInflation', 'isFemale' 'vessel'});

% Output data to a structure.
DataHoracek = struct('DataTable', DataTable, 'points', points, ...
    'face', face, 'FS', FS, 'J_DELAY', J_DELAY);

% Save the Struct to the output folder.
% Check if the folder exists.
if ~isfolder(OUTPUT_DIR)

    mkdir(OUTPUT_DIR);

end

% Save the file.
save(OUTPUT_FILEPATH, 'DataHoracek');

% Output run time.
t = toc;
disp([mfilename, ': ', num2str(t), ' seconds']);
end
%------------- END OF CODE -------------
