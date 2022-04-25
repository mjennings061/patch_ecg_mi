function DataStaff = miClassifier(DataStaff)
% Returns the a classification of STEMI for a given struct and lead
% configuration (schema). Returns results into annotations.decisionXX
% Inputs:
%   Data - Structure array. Contains the following fields:
%       * signals - Recordings extracted based on the work of C.
%       McCausland. Contains the following fields:
%           > extract_beat_WB - 9xN matrix of the ECG leads I-III; V1-V6.
%           > jPoint_n_WB - Vector of J-point locations for each lead.
%           > RWave_n_WB - Vector of R-wave annotations for each lead.
%           > SWave_n_WB - Vector of S-wave annotations for each lead.
%           > TWave_n_WB - Vector of T-wave annotations for each lead.
%       * name - String scalar. Recording label e.g. "001a".
%       * age - Scalar. Patient age in years.
%       * sex - Character. 'm' for male, 'f' for female.
%       * artery - String scalar. Location of the infact, or location of
%           the recording e.g. "BaselineRoom", or "dist circ".
%       * ann - Logical scalar. 0 for baseline recording, 1 for infarction.
%       * Lead18 - Nx15 matrix. Contains the derived 18-lead ECG.
%       * Lead22 - Nx19 matrix. Contains the derived 22-lead ECG.
%       * Nagenthiraja - Nx15 matrix. Contains the derived 18-lead ECG
%           using previously published coefficients.
%   Schema - Select which derivation method to use:
%       - '18 Lead' = Derivation of 18 lead
%           (I-III, V1-V6, V7-V9, V3R-V5R, aVR,aVL,aVF).
%       - '21 Lead' = Derivation of 21 lead
%           (I-III, V1-V6, V7-V12, V3R-V5R, aVR,aVL,aVF).
%       - 'Nagenthiraja' = Derivation of 18 lead using previously published
%           coefficients (I-III, V1-V6, V7-V9, V3R-V5R, aVR,aVL,aVF).

%------------- BEGIN CODE --------------

tic;

% Constants.
ST_CRITERIA = [50, 100, 150, 200, 250, 300];
nSTOptions = length(ST_CRITERIA);

% Extract annotations from the data into the annotations table.
nSubjects = length(DataStaff);

for iSubject = 1 : nSubjects

    % Extract the data for this subject.
    thisData = DataStaff(iSubject);

    %% Classify MI for the twelve lead ECG.
    decisionTwelveLead = detectSTEMI_12Lead(thisData);
    decisionTwelveLeadDep = detectSTEMI_12Lead_STdep(thisData);

    %% Classify MI for a patch.
    % Extract patch.
    thisPatch = thisData.signals.patch;

    % Get J-point sample number as V3.
    jPointIdx = thisData.signals.jPoint_n_WB(3);

    % Get J-point amplitude.
    thisSTAmplitude = thisPatch(jPointIdx, :);

    for iOption = 1 : nSTOptions

        % Get ST elevation required for a STEMI diagnosis, in mV.
        thisSTCriteria = ST_CRITERIA(iOption);

        % Classify MI if the ST elevation criteria is met.
        if any(abs(thisSTAmplitude) >= (thisSTCriteria / 1000))

            thisClassification = true;

        else

            thisClassification = false;

        end

        % Create the variable name.
        thisVarName = sprintf('patch_%duV', thisSTCriteria);

        % Output.
        DataStaff(iSubject).(thisVarName) = thisClassification;

    end

    % Append to the structure array.
    DataStaff(iSubject).Lead12 = decisionTwelveLead;
    DataStaff(iSubject).Lead12Dep = decisionTwelveLeadDep;

end

% Output run time.
t = toc;
disp([mfilename, ': ', num2str(t), ' seconds']);
end
%------------- END OF CODE -------------