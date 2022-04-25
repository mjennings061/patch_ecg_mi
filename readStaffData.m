function [DataStaff] = readStaffData(dataDir)
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
    DataStaff = importdata(OUTPUT_FILEPATH);
    return;

end

%% Main code.
% Import annotation data.
annotations = readtable(fullfile(dataDir, 'ann.xlsx'));

% List all data files in the directory.
matFiles = dir(fullfile(dataDir, '*.mat')); 

% Preallocate variables.
nFiles = length(matFiles);
DataStaff = struct([]);

% Load all info from each patient into one variable.
for iFile = 1 : nFiles

    % Get the file path.
    filePath = fullfile(dataDir, matFiles(iFile).name);
    
    % Load data.
    DataStaff(iFile).signals = load(filePath);

    % Get filename.
    [~, name, ~] = fileparts(matFiles(iFile).name);

    % Get metadata from ann.xlsx.
    % Find the row in ann matching the patient in question.
    annRow = annotations(strcmp(string(name), ...
        string(annotations.filename)), :);

    % Check if duplicates were detected in ann, and ignore them.
    if(size(annRow, 1) > 1)

        annRow = annRow(1,:);

    end
    
    % Save that row in a new ann variable.
    if(iFile == 1)

        AnnCropped = annRow;

    else

        AnnCropped = [AnnCropped; annRow]; %#ok

    end

    % Extract metadata and apply to struct.
    DataStaff(iFile).name = string(name);
    DataStaff(iFile).age = annRow.age;
    DataStaff(iFile).sex = char(annRow.gender);
    DataStaff(iFile).artery = string(annRow.artery);

    % Check for annotation as MI or not.
    if(contains(string(annRow.artery), ["Baseline", "Post"]))

        % 0 represents a baseline recording.
        DataStaff(iFile).ann = false;    

    else

        % 1 represents an occlusion (MI).
        DataStaff(iFile).ann = true;    

    end

end

%% Output.
% Save the Struct to the output folder.
% Check if the folder exists.
if ~isfolder(OUTPUT_DIR)

    mkdir(OUTPUT_DIR);

end

% Save the file.
save(OUTPUT_FILEPATH, 'DataStaff');

% Output run time.
t = toc;
disp([mfilename, ': ', num2str(t), ' seconds']);
end
%------------- END OF CODE -------------