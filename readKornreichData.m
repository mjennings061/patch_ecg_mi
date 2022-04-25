function [DataKornreich] = readKornreichData(dataDir)
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
    DataKornreich = importdata(OUTPUT_FILEPATH);
    return;

end

%% Main code.
% Import data.
dataNormal = importdata(fullfile(dataDir, 'data_Normal_352.mat'))';
dataMI = importdata(fullfile(dataDir, 'data_MI_352.mat'))';
dataLVH = importdata(fullfile(dataDir, 'data_LVH_352.mat'))';

% Number of recordings of each type.
nNormal = numel(dataNormal);
nMI = numel(dataMI);
nLVH = numel(dataLVH);

% Annotate files with disease type.
catNormal = repmat(categorical({'Normal'}), nNormal, 1);
catMI = repmat(categorical({'MI'}), nMI, 1);
catLVH = repmat(categorical({'LVH'}), nLVH, 1);

% Combine data and annotations.
dataCombined = [dataNormal; dataMI; dataLVH];
catCombined = [catNormal; catMI; catLVH];
DataKornreich = table(dataCombined, catCombined, ...
    'VariableNames', {'BSPM', 'Disease'});

%% Output.
% Save the Struct to the output folder.
% Check if the folder exists.
if ~isfolder(OUTPUT_DIR)

    mkdir(OUTPUT_DIR);

end

% Save the file.
save(OUTPUT_FILEPATH, 'DataKornreich');

% Output run time.
t = toc;
disp([mfilename, ': ', num2str(t), ' seconds']);
end
%------------- END OF CODE -------------