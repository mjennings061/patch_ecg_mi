function twelveLead = extractTwelveLeadBSPM(bspmData, masonLikarFlag)
% extractTwelveLeadBSPM - Extract the eight independent channels of the 
% twelve lead ECG from the Kornreich or Horacek BSPMs.    
%
% Input:
%    bspmData - 355xN matrix of BSPM data. Rows are leads, with columns as
%       samples.
%    masonLikarFlag - Logical scalar. True indicates the Mason-Likar ECG
%    configuration is to be returned.
%
% Output: 
%    twelveLead - One 8xN matrix wrt time. Rows represent leads, columns 
%       represent samples.
%                   time (t) -->-->
%       lead I    [n n-1 n-2 ... n-N]
%       lead II   [n n-1 n-2 ... n-N]
%       lead V1   [n n-1 n-2 ... n-N]
%       ...
%       lead V6   [n n-1 n-2 ... n-N]
%
% Example:
%   twelveLead = extractTwelveLeadBSPM(bspmData, masonLikarFlag);
%  
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if nargin < 2

    % Default is limb-lead configuration.
    masonLikarFlag = 0;

end

% Convert to a matrix.
if isa(bspmData, 'cell')

    bspmData = bspmData{:};

end

% Preallocation.
nSamples = size(bspmData, 2);
twelveLead = nan(8, nSamples); 

% Use the ML configuration if the flag is set.
if masonLikarFlag
    
    % Calculate the Mason-Likar configuration.
    RA = (bspmData(63, :) + bspmData(104, :)) / 2; 
    LA = (bspmData(53, :) + bspmData(93, :)) / 2; 
    LL = (3 * bspmData(346, :) + 2 * bspmData(347, :)) / 5;
    twelveLead(1, :) = LA - RA; % I.
    twelveLead(2, :) = LL - RA; % II.

else
    
    % Use the distal limb-lead configuration.
    twelveLead(1, :) = bspmData(2, :); % I.
    twelveLead(2, :) = bspmData(3, :); % II.

end

% Extract the remaining leads of the 12-lead ECG.
twelveLead(3, :) = bspmData(172, :); % V1.
twelveLead(4, :) = bspmData(174, :); % V2.
twelveLead(5, :) = (bspmData(195, :) + bspmData(196, :)) / 2; % V3.
twelveLead(6, :) = bspmData(219, :); % V4.
twelveLead(7, :) = (bspmData(220, :) + 2 * bspmData(221, :)) / 3; % V5.
twelveLead(8, :) = bspmData(222, :); % V6.

end