function ShortLeadsTable = electrodeDistanceFilter(SortedLeadsTable, ...
    points, faces, maxLeadDistance)
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

% Setup.
sortedLeads = table2array(SortedLeadsTable);
nLeads = length(sortedLeads);

% True when leads are longer than maxLeadDistance.
longLeadFlag = false(nLeads, 1);

for iLead = 1 : nLeads

    % Node numbers to calculate the distance between.
    nodes = sortedLeads(iLead, :);

    % Points for the selected nodes.
    nodePoints = points(nodes, :);

    % Calculate the distance between the two nodes.
    distance = pdist(nodePoints);

    % Set the flag if the distance is greater than allowed.
    if distance > maxLeadDistance
        
        longLeadFlag(iLead) = true;

    end

end

% Discard leads with a distance greater than allowed.
shortLeads = sortedLeads(~longLeadFlag, :);

% Save output to a table.
ShortLeadsTable = array2table(shortLeads, 'VariableNames', ...
    {'negativeNode', 'positiveNode'});

% Output run time.
t = toc;
disp([mfilename, ': ', num2str(t), ' seconds']);
end