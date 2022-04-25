function plotBSPM(DataHoracek, indexOfResponder, sslNodes, additionalSSL)
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
% Number of nodes required for the BSPM.
N_NODES = 352;

% Extract data from the struct.
jDelay = DataHoracek.J_DELAY;
points = DataHoracek.points;
faces = DataHoracek.face;

% Use only inflation recordings to emphasis the ST amplitude.
inflationIdx = indexOfResponder(2 : 2 : end);
bspmData = DataHoracek.DataTable.bspmData(inflationIdx);

% Create a triangulation object for plotting.
TriData = triangulation(faces, points);

%% Median amplitude at the ST-segment.
% Preallocation.
nSubjects = length(bspmData);
stSegments = nan(nSubjects, N_NODES);

for iSubject = 1 : nSubjects

    % Get the annotations for this subject.
    thisBSPM = bspmData{iSubject};
    thisAnnotation = thisBSPM(1, :);
    nSamples = length(thisAnnotation);

    % Find the ST segment.
    for iSample = 1 : nSamples

        if thisAnnotation(iSample) == 3

            % J-point found, calculate ST-segment amplitude for each node.
            stSegmentIdx = iSample + jDelay;
            thisStSegment = thisBSPM(4 : end, stSegmentIdx);
            stSegments(iSubject, :) = thisStSegment;

        end

    end

end

% Calculate the median ST amplitude for each node.
medianSTAmplitudes = median(stSegments);

%% Plot BSPM Figure.
% Plot the torso with median amplitudes as colours.
bspmPlot = figure();
trisurf(TriData, medianSTAmplitudes);
bspmPlot.Position = [700, 400, 400, 400];
title('BSPM at J+40ms (during inflation)'); 
xlabel('x (mm)');
ylabel('y (mm)');
zlabel('z (mm)');
set(gca,'linewidth',1.4);
hold on;
view(0,270); %rotate the graph
grid off;

% Plot the SSL.
Z_ADJUST = -5;
x = points(sslNodes, 1);
y = points(sslNodes, 2);
z = points(sslNodes, 3) + Z_ADJUST;
sslPlot = plot3(x, y, z);
sslPlot.Marker = '.';
sslPlot.MarkerSize = 30;
sslPlot.LineWidth = 2.5;
sslPlot.Color = 'w';

% Plot the spatially orthogonal lead if required.
if exist('additionalSSL', 'var')

    x = points(additionalSSL, 1);
    y = points(additionalSSL, 2);
    z = points(additionalSSL, 3) + Z_ADJUST;
    sslPlot = plot3(x, y, z);
    sslPlot.Marker = '.';
    sslPlot.MarkerSize = 20;
    sslPlot.LineWidth = 2;
    sslPlot.Color = 'k';

end

%% Plot V-leads.
% Extract V-lead x, y, z.
V_LEAD_SIZE = 15;
vLeadIdx = [169, 171, 192, 216, 218, 219];
x = points(vLeadIdx, 1);
y = points(vLeadIdx, 2);
z = points(vLeadIdx, 3);

% Plot V-leads as markers.
for iLead = 1 : 6

    plot3(x(iLead), y(iLead), z(iLead) + Z_ADJUST, '.k', ...
        'MarkerSize', V_LEAD_SIZE);

end

%% Configure axis and colourbar.
% Axes properties.
set(findall(gcf, '-property', 'FontWeight'), 'FontWeight', 'bold');
set(groot, 'defaulttextinterpreter', 'latex');
set(groot, 'defaultLegendInterpreter', 'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 9);

% Colour bar properties.
colourBar = colorbar;   % Colour legend at the side.
[~] = colourBar.LineWidth;    % Set linewidth of colour map to 1.5
colourBar.LineWidth = 1.4;
colourBar.FontSize = 9;
colourBar.TickLabelInterpreter = 'latex';
colourBar.Label.Interpreter = 'latex';
colourBar.Label.String = 'Amplitude ($\mu$V)';
colourBar.Label.Position = [-1,43.0001964569092,0];
shading interp; % Blend the lines to remove meshing
colormap jet;
colourBar.FontWeight = 'bold';
grid on;

%% Narrow the graph margins for publications
ax = gca;
outerpos = ax.OuterPosition;
ti = ax.TightInset; 
left = outerpos(1) + ti(1);
bottom = outerpos(2) + ti(2);
ax_width = outerpos(3) - ti(1) - ti(3);
ax_height = outerpos(4) - ti(2) - ti(4);
ax.Position = [left bottom ax_width ax_height];
hold off;

%% Output.
% Output run time.
t = toc;
disp([mfilename, ': ', num2str(t), ' seconds']);
end
