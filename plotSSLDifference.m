function plotSSLDifference(DataHoracek, idxToPlot, patchNodes)
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
LINE_WIDTH = 1.5;

% Extract data.
idx = table2array(idxToPlot(:, 1 : 2));
bspmData = DataHoracek.DataTable.bspmData(idx);
fs = DataHoracek.FS;

% Get BSPM for both baseline and inflation recordings.
baselineBspm = bspmData{1};
inflationBspm = bspmData{2};

% Trim unwanted data.
baselineBspm = baselineBspm(4 : end, :);
inflationBspm = inflationBspm(4 : end, :);

%% Main code.
% Calculate SSL.
sslNodes = patchNodes(1, :);
baselineSSL = baselineBspm(sslNodes(2), :) - baselineBspm(sslNodes(1), :);
inflationSSL = inflationBspm(sslNodes(2), :) - inflationBspm(sslNodes(1), :);

% Calculate spatially orthogonal lead.
orthNodes = patchNodes(2, :);
baselineOrth = baselineBspm(orthNodes(2), :) - baselineBspm(orthNodes(1), :);
inflationOrth = inflationBspm(orthNodes(2), :) - ...
    inflationBspm(orthNodes(1), :);

% Calculate number of samples.
nSamplesBaseline = numel(baselineSSL);
nSamplesInflation = numel(inflationSSL);
nSamplesMin = min(nSamplesBaseline, nSamplesInflation);

% Trim records to be the same length.
baselineSSL = baselineSSL(1 : nSamplesMin);
inflationSSL = inflationSSL(1 : nSamplesMin);
baselineOrth = baselineOrth(1 : nSamplesMin);
inflationOrth = inflationOrth(1 : nSamplesMin);

% Create time vector.
time = (0 : nSamplesMin - 1) / fs;

%% Plot.
% Setup figure.
Figure = figure();
Figure.Position = [10, 10, 800, 400];

% Plot SSL.
subplot(1, 2, 1);
plot(time, baselineSSL, 'LineWidth', LINE_WIDTH, 'Color', 'k', ...
    'LineStyle', '--');
hold on;
plot(time, inflationSSL, 'LineWidth', LINE_WIDTH, 'Color', 'k', ...
    'LineStyle', '-');
title('ST-Elevation Sensitive Lead');
xlabel('Time (s)');
ylabel('Amplitude ($\mu$V)');
legend('Baseline', 'PBI', 'Location', 'southeast');
hold off;
grid on;

% Plot orthogonal lead.
subplot(1, 2, 2);
plot(time, baselineOrth, 'LineWidth', LINE_WIDTH, 'Color', 'k', ...
    'LineStyle', '--');
hold on;
plot(time, inflationOrth, 'LineWidth', LINE_WIDTH, 'Color', 'k', ...
    'LineStyle', '-');
title('Spatially Orthogonal Lead');
xlabel('Time (s)');
ylabel('Amplitude ($\mu$V)');
legend('Baseline', 'PBI', 'Location', 'southeast');
hold off;
grid on;

% Output run time.
t = toc;
disp([mfilename, ': ', num2str(t), ' seconds']);
end