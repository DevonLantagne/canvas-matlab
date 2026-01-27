function init()
%INIT Initializes local data and token for future CLI calls.
% Calling .init() again will show current settings and offer to
% enter new ones.
%
% Init will prompt the user (via GUI dialogs) for:
%   Canvas URL (saved to config)
%   Canvas API Token (saved to secrets)

disp("Starting Canvas-MATLAB initialization...")

% Detect OS (order matters - macOS is also isunix)
if ismac
    % Code to run on Mac platform
    disp('Token storage not yet supported')
elseif isunix
    % Code to run on Linux platform
elseif ispc
    % Code to run on Windows platform
else
    disp('Platform not supported')
end

% Check if config already exists, if so load it as defaults for
% prompts.

% TODO

defaultUrl = "yourschool.instructure.com";

promptStr = sprintf("Enter the Canvas institution URL [%s]", defaultUrl);
url = input(promptStr, "s");
% append API url info:
url = "https://" + url + "/api/v1";

% Prompt for token


end
